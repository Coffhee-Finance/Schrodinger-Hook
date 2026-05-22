// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {CoffheeHook} from "../src/CoffheeHook.sol";

contract DeployCoffheeHook is Script {
    function run(address poolManager)
        external
        returns (CoffheeHook hook)
    {
        vm.startBroadcast();

        hook = new CoffheeHook(
            IPoolManager(poolManager)
        );

        vm.stopBroadcast();

        console2.log(
            "CoffheeHook deployed at:",
            address(hook)
        );
    }
}