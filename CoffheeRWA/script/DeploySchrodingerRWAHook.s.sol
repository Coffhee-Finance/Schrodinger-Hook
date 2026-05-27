// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {Schrodinger1155RWAHook} from "../src/Schrodinger1155RWAHook.sol";

contract DeploySchrodingerRWAHook is Script {
    function run(address poolManager)
        external
        returns (Schrodinger1155RWAHook hook)
    {
        vm.startBroadcast();

        hook = new Schrodinger1155RWAHook(
            IPoolManager(poolManager),
            msg.sender
        );

        vm.stopBroadcast();
    }
}