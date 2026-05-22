// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {
    InEbool,
    InEuint64
} from "cofhe-contracts/FHE.sol";

import {CoffheeHook} from "../src/CoffheeHook.sol";
import {CoffheeHookHarness} from "./CoffheeHookHarness.sol";
import {MockERC7984} from "./MockERC7984.sol";
import {MockNonERC7984} from "./MockNonERC7984.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {SwapParams} from "v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";

contract CoffheeHookTest is Test {
    CoffheeHook internal hook;
    CoffheeHookHarness internal harness;

    address internal poolManager = address(0xCAFE);
    address internal owner = address(0xBEEF);

    MockERC7984 internal tokenA;
    MockERC7984 internal tokenB;
    MockNonERC7984 internal badToken;

    function setUp() public {
        hook = new CoffheeHook(IPoolManager(poolManager));
        harness = new CoffheeHookHarness(IPoolManager(poolManager));

        tokenA = new MockERC7984();
        tokenB = new MockERC7984();
        badToken = new MockNonERC7984();
    }

    function testConstructorStoresPoolManager() public view {
        assertEq(address(hook.poolManager()), poolManager);
    }

    function testHookPermissions() public view {
        Hooks.Permissions memory permissions = hook.getHookPermissions();

        assertEq(permissions.beforeSwap, true);
        assertEq(permissions.afterSwap, true);

        assertEq(permissions.beforeInitialize, false);
        assertEq(permissions.afterInitialize, false);
        assertEq(permissions.beforeAddLiquidity, false);
        assertEq(permissions.afterAddLiquidity, false);
        assertEq(permissions.beforeRemoveLiquidity, false);
        assertEq(permissions.afterRemoveLiquidity, false);
        assertEq(permissions.beforeDonate, false);
        assertEq(permissions.afterDonate, false);
        assertEq(permissions.beforeSwapReturnDelta, false);
        assertEq(permissions.afterSwapReturnDelta, false);
        assertEq(permissions.afterAddLiquidityReturnDelta, false);
        assertEq(permissions.afterRemoveLiquidityReturnDelta, false);
    }

    function testCreatePlanRevertsWithZeroAssets() public {
        vm.expectRevert(CoffheeHook.InvalidAssetCount.selector);

        InEuint64 memory emptyUint;
        InEbool memory emptyBool;

        hook.createPlan(
            new InEuint64[](0),
            emptyUint,
            emptyUint,
            emptyUint,
            emptyUint,
            emptyUint,
            emptyBool
        );
    }

    function testCurrencyToTokenRejectsNativeToken() public {
        Currency nativeCurrency = Currency.wrap(address(0));

        vm.expectRevert(CoffheeHook.NativeTokenNotAllowed.selector);
        harness.exposedCurrencyToToken(nativeCurrency);
    }

    function testCurrencyToTokenReturnsERC20Address() public view {
        Currency currency = Currency.wrap(address(tokenA));

        address result = harness.exposedCurrencyToToken(currency);

        assertEq(result, address(tokenA));
    }

    function testRequireERC7984AcceptsERC7984Token() public view {
        harness.exposedRequireERC7984(address(tokenA));
    }

    function testRequireERC7984RejectsNonERC7984Token() public {
        vm.expectRevert(CoffheeHook.NonERC7984Token.selector);
        harness.exposedRequireERC7984(address(badToken));
    }

    function testBeforeSwapRejectsNonPoolManager() public {
        PoolKey memory key = _mockPoolKey();

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(1 ether),
            sqrtPriceLimitX96: uint160(0)
        });

        vm.expectRevert(CoffheeHook.OnlyPoolManager.selector);

        hook.beforeSwap(
            owner,
            key,
            params,
            ""
        );
    }

    function testAfterSwapRejectsNonPoolManager() public {
        PoolKey memory key = _mockPoolKey();

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(1 ether),
            sqrtPriceLimitX96: uint160(0)
        });

        BalanceDelta delta = BalanceDelta.wrap(0);

        vm.expectRevert(CoffheeHook.OnlyPoolManager.selector);

        hook.afterSwap(
            owner,
            key,
            params,
            delta,
            ""
        );
    }

    function testBeforeSwapAllowsPoolManagerWhenNoPlanLinked() public {
        PoolKey memory key = _mockPoolKey();

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(1 ether),
            sqrtPriceLimitX96: uint160(0)
        });

        vm.prank(poolManager);

        (bytes4 selector,, uint24 fee) = hook.beforeSwap(
            owner,
            key,
            params,
            ""
        );

        assertEq(selector, hook.beforeSwap.selector);
        assertEq(fee, 0);
    }

    function testAfterSwapAllowsPoolManagerWhenNoPlanLinked() public {
        PoolKey memory key = _mockPoolKey();

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(1 ether),
            sqrtPriceLimitX96: uint160(0)
        });

        BalanceDelta delta = BalanceDelta.wrap(0);

        vm.prank(poolManager);

        (bytes4 selector, int128 hookDelta) = hook.afterSwap(
            owner,
            key,
            params,
            delta,
            ""
        );

        assertEq(selector, hook.afterSwap.selector);
        assertEq(hookDelta, 0);
    }

    function _mockPoolKey() internal view returns (PoolKey memory key) {
        key = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
    }
}