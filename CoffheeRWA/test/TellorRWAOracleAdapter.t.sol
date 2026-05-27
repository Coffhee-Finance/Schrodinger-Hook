// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {TellorRWAOracleAdapter} from "../src/TellorRWAOracleAdapter.sol";
import {MockTellor} from "../src/mocks/MockTellor.sol";

contract TellorRWAOracleAdapterTest is Test {
    TellorRWAOracleAdapter internal adapter;
    MockTellor internal tellor;

    bytes32 internal constant QUERY_ID =
        keccak256("US_TREASURY_NAV");

    function setUp() public {
        vm.warp(2 days);

        tellor = new MockTellor();

        adapter = new TellorRWAOracleAdapter(
            address(tellor),
            address(this)
        );
    }

    function testSetQueryId() public {
        adapter.setQueryId(1, QUERY_ID);

        assertEq(adapter.navQueryIdOf(1), QUERY_ID);
    }

    function testLatestNAV() public {
        adapter.setQueryId(1, QUERY_ID);

        tellor.submitValue(QUERY_ID, 1_000_000e18);

        (uint256 nav,) = adapter.latestNAV(1);
        assertEq(nav, 1_000_000e18);
    }

    function testRevertWhenQueryNotSet() public {
        vm.expectRevert();

        adapter.latestNAV(1);
    }
}