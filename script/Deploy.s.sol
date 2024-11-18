// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import { FundraisingFactory } from "../src/FundraisingFactory.sol";
import { MockERC20 } from "../test/mock/MockERC20.sol";

contract DeployScript is Script {
    function setUp() public { }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy platform token
        MockERC20 platformToken = new MockERC20("Platform Token", "PTK");

        // Mint initial supply to deployer
        platformToken.mint(msg.sender, 1_000_000 * 1e18);

        // Deploy factory with platform token
        FundraisingFactory factory = new FundraisingFactory(address(platformToken));

        console2.log("Platform Token deployed to:", address(platformToken));
        console2.log("Fundraising Factory deployed to:", address(factory));

        vm.stopBroadcast();
    }
}
