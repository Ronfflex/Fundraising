// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { FundraisingFactory } from "../src/FundraisingFactory.sol";
import { FundraisingCampaign } from "../src/FundraisingCampaign.sol";
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

        uint256 minAmount = 100 ether;
        uint256 maxAmount = 1000 ether;
        uint256 startDate = block.timestamp + 1 days;
        uint256 endDate = block.timestamp + 30 days;

        uint256 requestId = factory.submitCampaignRequest(minAmount, maxAmount, startDate, endDate);

        console2.log("New campaign request submitted with ID:", requestId);

        FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestId);

        console2.log("Status of the request:", uint256(details.status));
        console2.log("Creator:", details.creator);

        vm.stopBroadcast();
    }

    function checkRequestStatus(uint256 requestId) public view {
        FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestId);

        console2.log("=== Details of the request ===");
        console2.log("ID:", requestId);
        console2.log("Creator:", details.creator);
        console2.log("Minimum amount:", details.tokenTargetMinAmount);
        console2.log("Maximum amount:", details.tokenTargetMaxAmount);
        console2.log("Beginning date:", details.startDate);
        console2.log("End date:", details.endDate);
        console2.log("Status:", uint256(details.status));
        console2.log("Campaign address:", details.campaignAddress);
    }

    function getCreatorRequests(address creator) public view {
        uint256[] memory requestIds = factory.getCreatorRequests(creator);

        console2.log("=== Creator", creator, "requests ===");
        console2.log("Total amount of requests:", requestIds.length);

        for (uint256 i = 0; i < requestIds.length; i++) {
            FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestIds[i]);

            console2.log("--- Request", i + 1, "---");
            console2.log("ID:", requestIds[i]);
            console2.log("Status:", uint256(details.status));
            console2.log("Campaign address:", details.campaignAddress);
        }
    }

    function reviewCampaign(uint256 requestId, bool approved) public {
        uint256 ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        vm.startBroadcast(ownerPrivateKey);

        factory.reviewCampaignRequest(requestId, approved);

        FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestId);

        if (approved) {
            console2.log("Campaign approved!");
            console2.log("Campaign address:", details.campaignAddress);
        } else {
            console2.log("Campaign rejected!");
        }

        vm.stopBroadcast();
    }

    function contributeToCampaign(address campaignAddress, uint256 amount, address contributionToken) public {
        uint256 contributorPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(contributorPrivateKey);

        MockERC20(contributionToken).approve(campaignAddress, amount);

        FundraisingCampaign campaign = FundraisingCampaign(campaignAddress);
        campaign.contribute(amount, MockERC20(contributionToken));

        console2.log("Contribution of", amount, "tokens made to the campaign");

        vm.stopBroadcast();
    }

    function getCampaignDetails(address campaignAddress) public view {
        FundraisingCampaign campaign = FundraisingCampaign(campaignAddress);

        (
            address _creator,
            uint256 _tokenTargetMinAmount,
            uint256 _tokenTargetMaxAmount,
            uint256 _startDate,
            uint256 _endDate,
            uint256 _totalCollected,
            bool _claimed,
            bool _isActive,
            bool _isSuccessful
        ) = campaign.getCampaignDetails();

        console2.log("=== Campaign Details ===");
        console2.log("Creator:", _creator);
        console2.log("Minimum target:", _tokenTargetMinAmount);
        console2.log("Maximum target:", _tokenTargetMaxAmount);
        console2.log("Start date:", _startDate);
        console2.log("End date:", _endDate);
        console2.log("Total collected:", _totalCollected);
        console2.log("Funds claimed:", _claimed);
        console2.log("Campaign active:", _isActive);
        console2.log("Campaign successful:", _isSuccessful);
    }

    function claimCampaignFunds(address campaignAddress) public {
        uint256 creatorPrivateKey = vm.envUint("CREATOR_PRIVATE_KEY");
        vm.startBroadcast(creatorPrivateKey);

        FundraisingCampaign campaign = FundraisingCampaign(campaignAddress);
        campaign.claimFunds();

        console2.log("Funds claimed successfully!");

        vm.stopBroadcast();
    }

    function requestRefund(address campaignAddress) public {
        uint256 contributorPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(contributorPrivateKey);

        FundraisingCampaign campaign = FundraisingCampaign(campaignAddress);
        campaign.refund();

        console2.log("Refund requested successfully!");

        vm.stopBroadcast();
    }
}
