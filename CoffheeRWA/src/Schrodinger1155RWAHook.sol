// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {
    FHE,
    ebool,
    euint64,
    InEbool,
    InEuint64
} from "cofhe-contracts/FHE.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary
} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";

import {IFrappecino1155} from "./interfaces/IFrappecino1155.sol";

contract Schrodinger1155RWAHook is Ownable {
    using PoolIdLibrary for PoolKey;

    IPoolManager public immutable poolManager;

    uint64 public constant BPS = 10_000;

    struct RWAPlan {
        address owner;
        bool active;

        address frappecino1155;
        uint256 tokenId;

        euint64 encryptedMinNAV;
        euint64 encryptedMaxDiscountBps;
        euint64 encryptedMaxOrderSize;
        euint64 encryptedTargetExposureBps;
        euint64 encryptedCurrentExposureBps;
        euint64 encryptedRiskLimitBps;
        ebool encryptedComplianceRequired;
    }

    mapping(address token => bool allowed) public isWhitelistedFrappecino;
    mapping(bytes32 planId => RWAPlan plan) private plans;
    mapping(PoolId poolId => bytes32 planId) public poolToPlan;

    event FrappecinoWhitelisted(address indexed token, bool allowed);
    event RWAPlanCreated(
        bytes32 indexed planId,
        address indexed owner,
        address indexed frappecino1155,
        uint256 tokenId
    );
    event RWAPoolLinked(bytes32 indexed planId, PoolId indexed poolId);
    event PrivateRWAIntentEvaluated(bytes32 indexed planId, PoolId indexed poolId);
    event PrivateRWAExposureUpdated(bytes32 indexed planId, PoolId indexed poolId);
    event AuditorAccessGranted(bytes32 indexed planId, address indexed auditor);

    error OnlyPoolManager();
    error NotPlanOwner();
    error InvalidPlan();
    error FrappecinoNotWhitelisted();
    error InvalidFrappecino1155();

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert OnlyPoolManager();
        _;
    }

    constructor(IPoolManager manager, address initialOwner)
        Ownable(initialOwner)
    {
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

    function setFrappecinoWhitelist(address token, bool allowed)
        external
        onlyOwner
    {
        if (
            !IERC165(token).supportsInterface(type(IFrappecino1155).interfaceId)
        ) {
            revert InvalidFrappecino1155();
        }

        isWhitelistedFrappecino[token] = allowed;

        emit FrappecinoWhitelisted(token, allowed);
    }

    function createRWAPlan(
        address frappecino1155,
        uint256 tokenId,
        InEuint64 calldata encryptedMinNAV,
        InEuint64 calldata encryptedMaxDiscountBps,
        InEuint64 calldata encryptedMaxOrderSize,
        InEuint64 calldata encryptedTargetExposureBps,
        InEuint64 calldata encryptedRiskLimitBps,
        InEbool calldata encryptedComplianceRequired
    ) external returns (bytes32 planId) {
        if (!isWhitelistedFrappecino[frappecino1155]) {
            revert FrappecinoNotWhitelisted();
        }

        planId = keccak256(
            abi.encode(
                msg.sender,
                frappecino1155,
                tokenId,
                block.chainid,
                block.number
            )
        );

        RWAPlan storage p = plans[planId];

        p.owner = msg.sender;
        p.active = true;
        p.frappecino1155 = frappecino1155;
        p.tokenId = tokenId;

        p.encryptedMinNAV = FHE.asEuint64(encryptedMinNAV);
        p.encryptedMaxDiscountBps = FHE.asEuint64(encryptedMaxDiscountBps);
        p.encryptedMaxOrderSize = FHE.asEuint64(encryptedMaxOrderSize);
        p.encryptedTargetExposureBps = FHE.asEuint64(encryptedTargetExposureBps);
        p.encryptedRiskLimitBps = FHE.asEuint64(encryptedRiskLimitBps);
        p.encryptedComplianceRequired = FHE.asEbool(encryptedComplianceRequired);

        _allowOwnerAndContract(p.encryptedMinNAV);
        _allowOwnerAndContract(p.encryptedMaxDiscountBps);
        _allowOwnerAndContract(p.encryptedMaxOrderSize);
        _allowOwnerAndContract(p.encryptedTargetExposureBps);
        _allowOwnerAndContract(p.encryptedRiskLimitBps);

        FHE.allowThis(p.encryptedComplianceRequired);
        FHE.allowSender(p.encryptedComplianceRequired);

        emit RWAPlanCreated(planId, msg.sender, frappecino1155, tokenId);
    }

    function linkPool(bytes32 planId, PoolKey calldata key) external {
        RWAPlan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotPlanOwner();
        if (!isWhitelistedFrappecino[p.frappecino1155]) {
            revert FrappecinoNotWhitelisted();
        }

        PoolId poolId = key.toId();
        poolToPlan[poolId] = planId;

        emit RWAPoolLinked(planId, poolId);
    }

    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata swapParams,
        bytes calldata
    )
        external
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        bytes32 planId = poolToPlan[key.toId()];

        if (planId != bytes32(0)) {
            RWAPlan storage p = plans[planId];

            if (p.active) {
                euint64 encryptedOrderSize =
                    _publicAmountToEncryptedAbs(swapParams.amountSpecified);

                ebool sizeOk = FHE.lte(
                    encryptedOrderSize,
                    p.encryptedMaxOrderSize
                );

                euint64 drift = _encryptedAbsDiff(
                    p.encryptedCurrentExposureBps,
                    p.encryptedTargetExposureBps
                );

                ebool riskOk = FHE.lte(drift, p.encryptedRiskLimitBps);

                ebool accepted = FHE.and(sizeOk, riskOk);

                FHE.allowThis(accepted);

                emit PrivateRWAIntentEvaluated(planId, key.toId());
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
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    )
        external
        onlyPoolManager
        returns (bytes4, int128)
    {
        bytes32 planId = poolToPlan[key.toId()];

        if (planId != bytes32(0)) {
            RWAPlan storage p = plans[planId];

            if (p.active) {
                euint64 encryptedDelta =
                    _publicDeltaToEncryptedAbs(delta.amount0());

                p.encryptedCurrentExposureBps = FHE.add(
                    p.encryptedCurrentExposureBps,
                    encryptedDelta
                );

                _allowOwnerAndContract(p.encryptedCurrentExposureBps);

                emit PrivateRWAExposureUpdated(planId, key.toId());
            }
        }

        return (this.afterSwap.selector, 0);
    }

    function deactivatePlan(bytes32 planId) external {
        RWAPlan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotPlanOwner();

        p.active = false;
    }

    function grantAuditorAccess(bytes32 planId, address auditor) external {
        RWAPlan storage p = plans[planId];

        if (p.owner == address(0)) revert InvalidPlan();
        if (p.owner != msg.sender) revert NotPlanOwner();

        FHE.allow(p.encryptedMinNAV, auditor);
        FHE.allow(p.encryptedMaxDiscountBps, auditor);
        FHE.allow(p.encryptedMaxOrderSize, auditor);
        FHE.allow(p.encryptedTargetExposureBps, auditor);
        FHE.allow(p.encryptedCurrentExposureBps, auditor);
        FHE.allow(p.encryptedRiskLimitBps, auditor);
        FHE.allow(p.encryptedComplianceRequired, auditor);

        emit AuditorAccessGranted(planId, auditor);
    }

    function _publicAmountToEncryptedAbs(int256 amount)
        internal
        returns (euint64)
    {
        uint256 absAmount = amount >= 0
            ? uint256(amount)
            : uint256(-amount);

        return FHE.asEuint64(uint64(absAmount));
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
        return FHE.select(aGreater, FHE.sub(a, b), FHE.sub(b, a));
    }

    function _allowOwnerAndContract(euint64 value) internal {
        FHE.allowThis(value);
        FHE.allowSender(value);
    }
}