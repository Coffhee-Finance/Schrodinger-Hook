// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {ReactiveRWAController} from "../src/ReactiveRWAController.sol";
import {MockMailbox} from "../src/mocks/MockMailbox.sol";

contract ReactiveRWAControllerTest is Test {
    ReactiveRWAController internal controller;
    MockMailbox internal mailbox;

    function setUp() public {
        mailbox = new MockMailbox();

        controller = new ReactiveRWAController(
            address(mailbox),
            address(this)
        );
    }

    function testSetHook() public {
        controller.setHook(address(0xBEEF));

        assertEq(controller.hook(), address(0xBEEF));
    }

    function testSetTrustedReactiveSender() public {
        controller.setTrustedReactiveSender(address(0xCAFE));

        assertEq(
            controller.trustedReactiveSender(),
            address(0xCAFE)
        );
    }

    function testAllowOriginDomain() public {
        controller.setAllowedOriginDomain(421614, true);

        assertTrue(controller.allowedOriginDomain(421614));
    }

    function testAllowRemoteSender() public {
        bytes32 sender = bytes32(uint256(123));

         controller.setAllowedRemoteSender(sender, true);

        assertTrue(controller.allowedRemoteSender(sender));
    }
}