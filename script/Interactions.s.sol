// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { FundraisingFactory } from "../src/FundraisingFactory.sol";
import { MockERC20 } from "../test/mock/MockERC20.sol";

contract Interactions is Script {
    FundraisingFactory public factory;
    MockERC20 public platformToken;

    function setUp() public {
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address tokenAddress = vm.envAddress("PLATFORM_TOKEN_ADDRESS");

        factory = FundraisingFactory(factoryAddress);
        platformToken = MockERC20(tokenAddress);
    }

    function createNewCampaign() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        uint256 requestId = factory.submitCampaignRequest(
            100 ether,
            1000 ether,
            block.timestamp + 1 days,
            block.timestamp + 30 days
        );

        console2.log(unicode"New campaign request submitted! Request ID:", requestId);

        vm.stopBroadcast();
    }

    function approveCampaign(uint256 requestId) public {
        uint256 ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");

        vm.startBroadcast(ownerPrivateKey);

        factory.reviewCampaignRequest(requestId, true);

        FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestId);

        console2.log(unicode"Campaign request", requestId, unicode"approved! Campaign address:", details.campaignAddress);

        vm.stopBroadcast();
    }
}
