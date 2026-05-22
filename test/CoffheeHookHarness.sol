// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CoffheeHook} from "../src/CoffheeHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

contract CoffheeHookHarness is CoffheeHook {
    constructor(IPoolManager manager) CoffheeHook(manager) {}

    function exposedCurrencyToToken(Currency currency)
        external
        pure
        returns (address)
    {
        return _currencyToToken(currency);
    }

    function exposedRequireERC7984(address token) external view {
        _requireERC7984(token);
    }
}