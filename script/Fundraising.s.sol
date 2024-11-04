// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FundraisingFactory} from "../src/Fundraising.sol";

contract FundraisingScript is Script {
    FundraisingFactory public Fundraising;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Fundraising = new FundraisingFactory();

        vm.stopBroadcast();
    }
}
