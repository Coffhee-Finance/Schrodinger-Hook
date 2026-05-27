// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MockTellor {
    struct DataPoint {
        bool exists;
        bytes value;
        uint256 timestamp;
    }

    mapping(bytes32 => DataPoint) public data;

    function submitValue(bytes32 queryId, uint256 value) external {
        data[queryId] = DataPoint({
            exists: true,
            value: abi.encode(value),
            timestamp: block.timestamp
        });
    }

    function getDataBefore(bytes32 queryId, uint256)
        external
        view
        returns (
            bool ifRetrieve,
            bytes memory value,
            uint256 timestampRetrieved
        )
    {
        DataPoint memory d = data[queryId];

        return (
            d.exists,
            d.value,
            d.timestamp
        );
    }
}