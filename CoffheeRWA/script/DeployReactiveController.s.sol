// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {ReactiveRWAController} from "../src/ReactiveRWAController.sol";

contract DeployReactiveController is Script {
    function run(address mailbox)
        external
        returns (ReactiveRWAController controller)
    {
        vm.startBroadcast();

        controller = new ReactiveRWAController(
            mailbox,
            msg.sender
        );

        vm.stopBroadcast();
    }
}