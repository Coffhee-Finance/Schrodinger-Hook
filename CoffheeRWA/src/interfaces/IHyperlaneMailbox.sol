// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IHyperlaneMailbox {
    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external payable returns (bytes32 messageId);
}

interface IHyperlaneRecipient {
    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata message
    ) external payable;
}