// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MockMailbox {
    event Dispatch(
        uint32 destination,
        bytes32 recipient,
        bytes message
    );

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external payable returns (bytes32 messageId) {
        emit Dispatch(
            destinationDomain,
            recipientAddress,
            messageBody
        );

        messageId = keccak256(
            abi.encode(
                destinationDomain,
                recipientAddress,
                messageBody,
                block.timestamp
            )
        );
    }
}