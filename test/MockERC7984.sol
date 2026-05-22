// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {euint64} from "cofhe-contracts/FHE.sol";

interface IERC7984MinimalForTest is IERC165 {
    function confidentialBalanceOf(address account)
        external
        view
        returns (euint64);
}

contract MockERC7984 is IERC7984MinimalForTest {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC7984MinimalForTest).interfaceId;
    }

    function confidentialBalanceOf(address)
        external
        pure
        returns (euint64)
    {
        return euint64.wrap(0);
    }
}