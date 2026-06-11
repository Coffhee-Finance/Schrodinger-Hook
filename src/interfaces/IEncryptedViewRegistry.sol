// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IEncryptedViewRegistry {
    enum ViewKind {
        TokenBalance,
        ERC1155Balance,
        HookExposure,
        HookTarget,
        HookLastRebalance
    }

    event ViewAccessGranted(
        address indexed owner,
        address indexed viewer,
        ViewKind indexed kind,
        bytes32 handleId
    );
}