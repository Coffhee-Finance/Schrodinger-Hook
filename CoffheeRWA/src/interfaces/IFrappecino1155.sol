// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IFrappecino1155 is IERC1155 {
    function rwaAssetOf(uint256 tokenId) external view returns (address);
    function maturityOf(uint256 tokenId) external view returns (uint256);
    function isTransferRestricted(uint256 tokenId) external view returns (bool);
}