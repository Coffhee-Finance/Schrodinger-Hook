// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {
    InEbool,
    InEuint64
} from "cofhe-contracts/FHE.sol";

import {Schrodinger1155RWAHook} from "../src/Schrodinger1155RWAHook.sol";
import {MockFrappecino1155} from "../src/mocks/MockFrappecino1155.sol";
import {MockPoolManager} from "../src/mocks/MockPoolManager.sol";

contract Schrodinger1155RWAHookTest is Test {
    Schrodinger1155RWAHook internal hook;
    MockFrappecino1155 internal frappecino;
    MockPoolManager internal manager;

    function setUp() public {
        manager = new MockPoolManager();

        hook = new Schrodinger1155RWAHook(
            IPoolManager(address(manager)),
            address(this)
        );

        frappecino = new MockFrappecino1155();
    }

    function testWhitelistFrappecino() public {
        hook.setFrappecinoWhitelist(
            address(frappecino),
            true
        );

        assertTrue(
            hook.isWhitelistedFrappecino(address(frappecino))
        );
    }

     function testGetHookPermissions() public {
        Hooks.Permissions memory permissions =
            hook.getHookPermissions();

        assertTrue(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
    }

    function testCreatePlanRevertsWhenNotWhitelisted() public {
        InEuint64 memory emptyUint;
        InEbool memory emptyBool;

        vm.expectRevert();

        hook.createRWAPlan(
            address(frappecino),
            1,
            emptyUint,
            emptyUint,
            emptyUint,
            emptyUint,
            emptyUint,
            emptyBool
        );
    }
}