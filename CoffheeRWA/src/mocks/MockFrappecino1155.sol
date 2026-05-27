// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IFrappecino1155} from "../interfaces/IFrappecino1155.sol";

contract MockFrappecino1155 is ERC1155, Ownable, IFrappecino1155 {
    mapping(uint256 => address) public rwaAsset;
    mapping(uint256 => uint256) public maturity;
    mapping(uint256 => bool) public restricted;

    constructor()
        ERC1155("https://coffhee.finance/api/frappecino/{id}.json")
        Ownable(msg.sender)
    {}

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        address rwa,
        uint256 maturityDate,
        bool isRestricted
    ) external onlyOwner {
        rwaAsset[tokenId] = rwa;
        maturity[tokenId] = maturityDate;
        restricted[tokenId] = isRestricted;

        _mint(to, tokenId, amount, "");
    }

    function rwaAssetOf(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        return rwaAsset[tokenId];
    }

    function maturityOf(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return maturity[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IFrappecino1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function isTransferRestricted(uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return restricted[tokenId];
    }
}