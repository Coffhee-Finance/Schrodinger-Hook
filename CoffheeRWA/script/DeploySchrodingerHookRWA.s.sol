// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {Schrodinger1155RWAHook} from "../src/Schrodinger1155RWAHook.sol";
import {ReactiveRWAController} from "../src/ReactiveRWAController.sol";
import {TellorRWAOracleAdapter} from "../src/TellorRWAOracleAdapter.sol";

contract DeploySchrodingerHookRWA is Script {
    function run(
        address poolManager,
        address hyperlaneMailbox,
        address tellor
    )
        external
        returns (
            Schrodinger1155RWAHook hook,
            ReactiveRWAController controller,
            TellorRWAOracleAdapter oracleAdapter
        )
    {
        vm.startBroadcast();

        hook = new Schrodinger1155RWAHook(
            IPoolManager(poolManager),
            msg.sender
        );

        controller = new ReactiveRWAController(
            hyperlaneMailbox,
            msg.sender
        );

        oracleAdapter = new TellorRWAOracleAdapter(
            tellor,
            msg.sender
        );

        controller.setHook(address(hook));

        vm.stopBroadcast();

        console2.log("Schrodinger1155RWAHook:", address(hook));
        console2.log("ReactiveRWAController:", address(controller));
        console2.log("TellorRWAOracleAdapter:", address(oracleAdapter));
    }
}