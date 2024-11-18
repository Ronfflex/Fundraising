// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { FundraisingCampaign } from "../src/FundraisingCampaign.sol";
import { MockERC20 } from "./mock/MockERC20.sol";

contract FundraisingCampaignTest is Test {
    FundraisingCampaign public campaign;
    MockERC20 public platformToken;
    MockERC20 public contributionToken;

    address public owner;
    address public creator;
    address public contributor1;
    address public contributor2;

    uint256 public startDate;
    uint256 public endDate;
    uint256 public minAmount;
    uint256 public maxAmount;

    event ContributionReceived(
        address indexed contributor, address indexed token, uint256 amount, uint256 platformTokenAmount
    );
    event FundsClaimed(address indexed creator, uint256 amount);
    event RefundProcessed(address indexed contributor, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        creator = makeAddr("creator");
        contributor1 = makeAddr("contributor1");
        contributor2 = makeAddr("contributor2");

        startDate = block.timestamp + 1 days;
        endDate = block.timestamp + 10 days;
        minAmount = 100e18;
        maxAmount = 1000e18;

        vm.startPrank(owner);
        platformToken = new MockERC20("Platform Token", "PTK");
        contributionToken = new MockERC20("Contribution Token", "CTK");

        campaign = new FundraisingCampaign(creator, minAmount, maxAmount, startDate, endDate, address(platformToken));
        vm.stopPrank();

        contributionToken.mint(contributor1, 1000e18);
        contributionToken.mint(contributor2, 1000e18);
        platformToken.mint(address(campaign), 10000e18);
    }

    function test_Constructor() public {
        assertEq(campaign.owner(), owner);
        assertEq(campaign.creator(), creator);
        assertEq(campaign.tokenTargetMinAmount(), minAmount);
        assertEq(campaign.tokenTargetMaxAmount(), maxAmount);
        assertEq(campaign.startDate(), startDate);
        assertEq(campaign.endDate(), endDate);
        assertEq(address(campaign.platformToken()), address(platformToken));
    }

    function test_Contribute() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 500e18);

        vm.expectEmit(true, true, false, true);
        emit ContributionReceived(contributor1, address(contributionToken), 500e18, 500e18);

        campaign.contribute(500e18, contributionToken);

        assertEq(campaign.totalCollected(), 500e18);
        assertEq(campaign.contributions(contributor1), 500e18);
        assertEq(contributionToken.balanceOf(address(campaign)), 500e18);

        vm.stopPrank();
    }

    function testFail_Contribute_BeforeStart() public {
        vm.prank(contributor1);
        campaign.contribute(100e18, contributionToken);
    }

    function testFail_Contribute_AfterEnd() public {
        vm.warp(endDate + 1);
        vm.prank(contributor1);
        campaign.contribute(100e18, contributionToken);
    }

    function testFail_Contribute_ExceedsMax() public {
        vm.warp(startDate + 1);
        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 1100e18);
        campaign.contribute(1100e18, contributionToken);
        vm.stopPrank();
    }

    function test_ClaimFunds_Successful() public {
        // Setup successful campaign
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 500e18);
        campaign.contribute(500e18, contributionToken);
        vm.stopPrank();

        vm.warp(endDate + 1);

        uint256 initialCreatorBalance = platformToken.balanceOf(creator);

        vm.startPrank(creator);
        vm.expectEmit(true, false, false, true);
        emit FundsClaimed(creator, 500e18);

        campaign.claimFunds();

        assertEq(platformToken.balanceOf(creator), initialCreatorBalance + 500e18);
        assertTrue(campaign.claimed());

        vm.stopPrank();
    }

    function testFail_ClaimFunds_NotEnded() public {
        vm.warp(startDate + 1);
        vm.prank(creator);
        campaign.claimFunds();
    }

    function testFail_ClaimFunds_MinNotReached() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 50e18);
        campaign.contribute(50e18, contributionToken);
        vm.stopPrank();

        vm.warp(endDate + 1);

        vm.prank(creator);
        campaign.claimFunds();
    }

    function test_Refund() public {
        // Setup failed campaign
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 50e18);
        campaign.contribute(50e18, contributionToken);
        vm.stopPrank();

        vm.warp(endDate + 1);

        uint256 initialBalance = platformToken.balanceOf(contributor1);

        vm.startPrank(contributor1);
        vm.expectEmit(true, false, false, true);
        emit RefundProcessed(contributor1, 50e18);

        campaign.refund();

        assertEq(platformToken.balanceOf(contributor1), initialBalance + 50e18);
        assertEq(campaign.contributions(contributor1), 0);

        vm.stopPrank();
    }

    function testFail_Refund_CampaignSuccessful() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 500e18);
        campaign.contribute(500e18, contributionToken);
        vm.stopPrank();

        vm.warp(endDate + 1);

        vm.prank(contributor1);
        campaign.refund();
    }

    function test_GetCampaignDetails() public {
        vm.warp(startDate + 1);

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

        assertEq(_creator, creator);
        assertEq(_tokenTargetMinAmount, minAmount);
        assertEq(_tokenTargetMaxAmount, maxAmount);
        assertEq(_startDate, startDate);
        assertEq(_endDate, endDate);
        assertEq(_totalCollected, 0);
        assertFalse(_claimed);
        assertTrue(_isActive);
        assertFalse(_isSuccessful);
    }

    function testFail_Constructor_ZeroCreator() public {
        new FundraisingCampaign(address(0), minAmount, maxAmount, startDate, endDate, address(platformToken));
    }

    function testFail_Constructor_ZeroToken() public {
        new FundraisingCampaign(creator, minAmount, maxAmount, startDate, endDate, address(0));
    }

    function testFail_Constructor_InvalidDates() public {
        new FundraisingCampaign(
            creator,
            minAmount,
            maxAmount,
            endDate, // startDate > endDate
            startDate,
            address(platformToken)
        );
    }

    function testFail_Constructor_InvalidAmounts() public {
        new FundraisingCampaign(
            creator,
            maxAmount, // minAmount > maxAmount
            minAmount,
            startDate,
            endDate,
            address(platformToken)
        );
    }

    function testFail_Contribute_ZeroAmount() public {
        vm.warp(startDate + 1);
        vm.prank(contributor1);
        campaign.contribute(0, contributionToken);
    }

    function testFail_Contribute_ZeroToken() public {
        vm.warp(startDate + 1);
        vm.prank(contributor1);
        campaign.contribute(100e18, MockERC20(address(0)));
    }

    function testFail_Contribute_ExactlyMaxAmount() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), maxAmount);
        campaign.contribute(maxAmount, contributionToken);
        campaign.contribute(1, contributionToken); // Devrait échouer car dépasserait le max
        vm.stopPrank();
    }

    function test_Contribute_MultipleContributors() public {
        vm.warp(startDate + 1);

        // Premier contributeur
        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 300e18);
        campaign.contribute(300e18, contributionToken);
        vm.stopPrank();

        // Deuxième contributeur
        vm.startPrank(contributor2);
        contributionToken.approve(address(campaign), 200e18);
        campaign.contribute(200e18, contributionToken);
        vm.stopPrank();

        assertEq(campaign.totalCollected(), 500e18);
        assertEq(campaign.contributions(contributor1), 300e18);
        assertEq(campaign.contributions(contributor2), 200e18);
    }

    function testFail_ClaimFunds_NotCreator() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 500e18);
        campaign.contribute(500e18, contributionToken);
        vm.stopPrank();

        vm.warp(endDate + 1);

        vm.prank(contributor1); // Not creator
        campaign.claimFunds();
    }

    function testFail_ClaimFunds_AlreadyClaimed() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 500e18);
        campaign.contribute(500e18, contributionToken);
        vm.stopPrank();

        vm.warp(endDate + 1);

        vm.startPrank(creator);
        campaign.claimFunds();
        campaign.claimFunds(); // Should fail
        vm.stopPrank();
    }

    function testFail_Refund_NotContributed() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 50e18);
        campaign.contribute(50e18, contributionToken);
        vm.stopPrank();

        vm.warp(endDate + 1);

        vm.prank(contributor2); // Hasn't contributed
        campaign.refund();
    }

    function testFail_Refund_CampaignNotEnded() public {
        vm.warp(startDate + 1);

        vm.startPrank(contributor1);
        contributionToken.approve(address(campaign), 50e18);
        campaign.contribute(50e18, contributionToken);

        campaign.refund(); // Campaign still active
        vm.stopPrank();
    }
}
