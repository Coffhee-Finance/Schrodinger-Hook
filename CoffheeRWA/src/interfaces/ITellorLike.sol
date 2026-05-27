// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITellorLike {
    function getDataBefore(bytes32 queryId, uint256 timestamp)
        external
        view
        returns (
            bool ifRetrieve,
            bytes memory value,
            uint256 timestampRetrieved
        );
}