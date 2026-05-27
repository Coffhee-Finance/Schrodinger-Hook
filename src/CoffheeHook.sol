// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// CoffheeHook ArbSepolia Address: 0xDb58A140928669d674D7a788394073C231d78724
// Private Rebalancing Hook built on top of Uniswap V4

import {
    FHE,
    ebool,
    euint64,
    InEbool,
    InEuint64
} from "cofhe-contracts/FHE.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {SwapParams} from "v4-core/src/types/PoolOperation.sol";
import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary
} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";

interface IERC7984Minimal is IERC165 {
    function confidentialBalanceOf(address account)
        external
        view
        returns (euint64);
}

contract CoffheeHook {
    using PoolIdLibrary for PoolKey;

    IPoolManager public immutable poolManager;

    uint8 public constant MAX_ASSETS = 8;
    uint64 public constant BPS = 10_000;

    bytes4 internal constant ERC7984_INTERFACE_ID =
        type(IERC7984Minimal).interfaceId;

    struct Plan {
        address owner;
        bool active;
        uint8 assetCount;

        mapping(uint8 asset => euint64) targetBps;
        mapping(uint8 asset => euint64) exposure;
        mapping(uint8 asset => euint64) lastRebalanceDelta;

        euint64 rebalanceThresholdBps;
        euint64 hedgeIntensityBps;
        euint64 volatilityBps;
        euint64 feeAprBps;
        euint64 timingSeed;
        ebool complianceEnabled;
    }

    mapping(bytes32 planId => Plan plan) private plans;
    mapping(PoolId poolId => bytes32 planId) public poolToPlan;
    mapping(PoolId poolId => uint8 assetIndex) public poolToAsset;
    mapping(address token => bool allowed) public isAllowedERC7984Token;

    event PlanCreated(bytes32 indexed planId, address indexed owner);
    event PlanDeactivated(bytes32 indexed planId);
    event PoolLinked(
        bytes32 indexed planId,
        PoolId indexed poolId,
        uint8 indexed assetIndex,
        address token0,
        address token1
    );
    event PrivateRebalanceEvaluated(bytes32 indexed planId, PoolId indexed poolId);
    event EncryptedExposureUpdated(bytes32 indexed planId, PoolId indexed poolId);
    event RiskInputsUpdated(bytes32 indexed planId);
    event AuditorAccessGranted(
        bytes32 indexed planId,
        address indexed auditor,
        uint8 indexed asset
    );

    error NotOwner();
    error InvalidPlan();
    error InvalidAssetCount();
    error NonERC7984Token();
    error NativeTokenNotAllowed();
    error OnlyPoolManager();

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert OnlyPoolManager();
        _;
    }

    constructor(IPoolManager manager) {
        poolManager = manager;
    }

    function getHookPermissions()
        public
        pure
        returns (Hooks.Permissions memory)
    {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function createPlan(
        InEuint64[] calldata encryptedTargets,
        InEuint64 calldata encryptedRebalanceThresholdBps,
        InEuint64 calldata encryptedHedgeIntensityBps,
        InEuint64 calldata encryptedVolatilityBps,
        InEuint64 calldata encryptedFeeAprBps,
        InEuint64 calldata encryptedTimingSeed,
        InEbool calldata encryptedComplianceEnabled
    ) external returns (bytes32 planId) {
        uint256 len = encryptedTargets.length;

        if (len == 0 || len > MAX_ASSETS) {
            revert InvalidAssetCount();
        }

        planId = keccak256(
            abi.encode(
                msg.sender,
                block.chainid,
                block.number,
                address(this),
                len
            )
        );

        Plan storage p = plans[planId];

        p.owner = msg.sender;
        p.active = true;
        p.assetCount = uint8(len);

        p.rebalanceThresholdBps = FHE.asEuint64(encryptedRebalanceThresholdBps);
        p.hedgeIntensityBps = FHE.asEuint64(encryptedHedgeIntensityBps);
        p.volatilityBps = FHE.asEuint64(encryptedVolatilityBps);
        p.feeAprBps = FHE.asEuint64(encryptedFeeAprBps);
        p.timingSeed = FHE.asEuint64(encryptedTimingSeed);
        p.complianceEnabled = FHE.asEbool(encryptedComplianceEnabled);

        _allowOwnerAndContract(p.rebalanceThresholdBps);
        _allowOwnerAndContract(p.hedgeIntensityBps);
        _allowOwnerAndContract(p.volatilityBps);
        _allowOwnerAndContract(p.feeAprBps);
        _allowOwnerAndContract(p.timingSeed);

        FHE.allowThis(p.complianceEnabled);
        FHE.allowSender(p.complianceEnabled);

        for (uint8 i = 0; i < len; i++) {
            p.targetBps[i] = FHE.asEuint64(encryptedTargets[i]);
            _allowOwnerAndContract(p.targetBps[i]);
        }

        emit PlanCreated(planId, msg.sender);
    }

    function linkPool(
        bytes32 planId,
        PoolKey calldata key,
        uint8 assetIndex
    ) external {
        Plan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotOwner();
        if (assetIndex >= p.assetCount) revert InvalidAssetCount();

        address token0 = _currencyToToken(key.currency0);
        address token1 = _currencyToToken(key.currency1);

        _requireERC7984(token0);
        _requireERC7984(token1);

        isAllowedERC7984Token[token0] = true;
        isAllowedERC7984Token[token1] = true;

        PoolId poolId = key.toId();

        poolToPlan[poolId] = planId;
        poolToAsset[poolId] = assetIndex;

        emit PoolLinked(planId, poolId, assetIndex, token0, token1);
    }

    function updateEncryptedRiskInputs(
        bytes32 planId,
        InEuint64 calldata encryptedVolatilityBps,
        InEuint64 calldata encryptedFeeAprBps,
        InEuint64 calldata encryptedRebalanceThresholdBps
    ) external {
        Plan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotOwner();

        p.volatilityBps = FHE.asEuint64(encryptedVolatilityBps);
        p.feeAprBps = FHE.asEuint64(encryptedFeeAprBps);
        p.rebalanceThresholdBps = FHE.asEuint64(encryptedRebalanceThresholdBps);

        _allowOwnerAndContract(p.volatilityBps);
        _allowOwnerAndContract(p.feeAprBps);
        _allowOwnerAndContract(p.rebalanceThresholdBps);

        emit RiskInputsUpdated(planId);
    }

    function deactivatePlan(bytes32 planId) external {
        Plan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotOwner();

        p.active = false;

        emit PlanDeactivated(planId);
    }

    function beforeSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        bytes calldata
    )
        external
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();
        bytes32 planId = poolToPlan[poolId];

        if (planId != bytes32(0)) {
            Plan storage p = plans[planId];

            if (p.active) {
                uint8 asset = poolToAsset[poolId];

                euint64 drift = _encryptedAbsDiff(
                    p.exposure[asset],
                    p.targetBps[asset]
                );

                euint64 threshold = _volatilityAdjustedThreshold(p);

                ebool shouldRebalance = FHE.gt(drift, threshold);

                FHE.allowThis(shouldRebalance);

                emit PrivateRebalanceEvaluated(planId, poolId);
            }
        }

        return (
            this.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    )
        external
        onlyPoolManager
        returns (bytes4, int128)
    {
        PoolId poolId = key.toId();
        bytes32 planId = poolToPlan[poolId];

        if (planId != bytes32(0)) {
            Plan storage p = plans[planId];

            if (p.active) {
                uint8 asset = poolToAsset[poolId];

                euint64 encryptedDelta = _publicDeltaToEncryptedAbs(
                    delta.amount0()
                );

                p.exposure[asset] = FHE.add(
                    p.exposure[asset],
                    encryptedDelta
                );

                euint64 drift = _encryptedAbsDiff(
                    p.exposure[asset],
                    p.targetBps[asset]
                );

                p.lastRebalanceDelta[asset] =
                    _sizedEncryptedRebalanceDelta(p, drift);

                _allowOwnerAndContract(p.exposure[asset]);
                _allowOwnerAndContract(p.lastRebalanceDelta[asset]);

                emit EncryptedExposureUpdated(planId, poolId);
            }
        }

        return (this.afterSwap.selector, 0);
    }

    function encryptedTargetBpsOf(bytes32 planId, uint8 asset)
        external
        view
        returns (euint64)
    {
        Plan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotOwner();

        return p.targetBps[asset];
    }

    function encryptedExposure(bytes32 planId, uint8 asset)
        external
        view
        returns (euint64)
    {
        Plan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotOwner();

        return p.exposure[asset];
    }

    function encryptedLastRebalanceDelta(bytes32 planId, uint8 asset)
        external
        view
        returns (euint64)
    {
        Plan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotOwner();

        return p.lastRebalanceDelta[asset];
    }

    function grantAuditorAccess(
        bytes32 planId,
        address auditor,
        uint8 asset
    ) external {
        Plan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotOwner();
        if (asset >= p.assetCount) revert InvalidAssetCount();

        FHE.allow(p.targetBps[asset], auditor);
        FHE.allow(p.exposure[asset], auditor);
        FHE.allow(p.lastRebalanceDelta[asset], auditor);
        FHE.allow(p.rebalanceThresholdBps, auditor);
        FHE.allow(p.hedgeIntensityBps, auditor);
        FHE.allow(p.volatilityBps, auditor);
        FHE.allow(p.feeAprBps, auditor);
        FHE.allow(p.timingSeed, auditor);
        FHE.allow(p.complianceEnabled, auditor);

        emit AuditorAccessGranted(planId, auditor, asset);
    }

    function _currencyToToken(Currency currency)
        internal
        pure
        returns (address token)
    {
        token = Currency.unwrap(currency);

        if (token == address(0)) {
            revert NativeTokenNotAllowed();
        }
    }

    function _requireERC7984(address token) internal view {
        bool ok = IERC165(token).supportsInterface(ERC7984_INTERFACE_ID);

        if (!ok) {
            revert NonERC7984Token();
        }
    }

    function _publicDeltaToEncryptedAbs(int128 amount)
        internal
        returns (euint64)
    {
        uint128 absAmount = amount >= 0
            ? uint128(amount)
            : uint128(-amount);

        return FHE.asEuint64(uint64(absAmount));
    }

    function _encryptedAbsDiff(euint64 a, euint64 b)
        internal
        returns (euint64)
    {
        ebool aGreater = FHE.gt(a, b);

        euint64 forward = FHE.sub(a, b);
        euint64 backward = FHE.sub(b, a);

        return FHE.select(aGreater, forward, backward);
    }

    function _volatilityAdjustedThreshold(Plan storage p)
        internal
        returns (euint64)
    {
        euint64 volatilityBuffer = FHE.div(
            p.volatilityBps,
            FHE.asEuint64(4)
        );

        euint64 feeCredit = FHE.div(
            p.feeAprBps,
            FHE.asEuint64(8)
        );

        euint64 rawThreshold = FHE.add(
            p.rebalanceThresholdBps,
            volatilityBuffer
        );

        ebool thresholdAboveFeeCredit = FHE.gt(
            rawThreshold,
            feeCredit
        );

        return FHE.select(
            thresholdAboveFeeCredit,
            FHE.sub(rawThreshold, feeCredit),
            FHE.asEuint64(1)
        );
    }

    function _sizedEncryptedRebalanceDelta(
        Plan storage p,
        euint64 drift
    ) internal returns (euint64) {
        euint64 weighted = FHE.mul(
            drift,
            p.hedgeIntensityBps
        );

        return FHE.div(
            weighted,
            FHE.asEuint64(BPS)
        );
    }

    function _allowOwnerAndContract(euint64 value) internal {
        FHE.allowThis(value);
        FHE.allowSender(value);
    }
}
