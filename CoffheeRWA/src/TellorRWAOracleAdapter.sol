// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//ArbSepolia address: 0x1711bF462B02b05579787F9b5be9D40d6721834e
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITellorLike} from "./interfaces/ITellorLike.sol";

contract TellorRWAOracleAdapter is Ownable {
    ITellorLike public immutable tellor;

    uint256 public staleAfter = 1 days;

    mapping(uint256 tokenId => bytes32 queryId) public navQueryIdOf;

    event QueryIdSet(uint256 indexed tokenId, bytes32 indexed queryId);
    event StaleAfterUpdated(uint256 staleAfter);

    error QueryNotSet();
    error TellorValueUnavailable();
    error TellorValueStale();

    constructor(address tellorAddress, address initialOwner)
        Ownable(initialOwner)
    {
        tellor = ITellorLike(tellorAddress);
    }

    function setQueryId(uint256 tokenId, bytes32 queryId) external onlyOwner {
        navQueryIdOf[tokenId] = queryId;
        emit QueryIdSet(tokenId, queryId);
    }

    function setStaleAfter(uint256 newStaleAfter) external onlyOwner {
        staleAfter = newStaleAfter;
        emit StaleAfterUpdated(newStaleAfter);
    }

    function latestNAV(uint256 tokenId)
        external
        view
        returns (uint256 nav, uint256 timestampRetrieved)
    {
        bytes32 queryId = navQueryIdOf[tokenId];
        if (queryId == bytes32(0)) revert QueryNotSet();

        (
            bool ok,
            bytes memory value,
            uint256 timestamp
        ) = tellor.getDataBefore(queryId, block.timestamp - 15 minutes);

        if (!ok) revert TellorValueUnavailable();
        if (block.timestamp - timestamp > staleAfter) revert TellorValueStale();

        nav = abi.decode(value, (uint256));
        timestampRetrieved = timestamp;
    }
}
