// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {TellorRWAOracleAdapter} from "../src/TellorRWAOracleAdapter.sol";

contract DeployTellorAdapter is Script {
    function run(address tellor)
        external
        returns (TellorRWAOracleAdapter adapter)
    {
        vm.startBroadcast();

        adapter = new TellorRWAOracleAdapter(
            tellor,
            msg.sender
        );

        vm.stopBroadcast();
    }
}