// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { FundraisingFactory } from "../src/FundraisingFactory.sol";
import { FundraisingCampaign } from "../src/FundraisingCampaign.sol";
import { MockERC20 } from "./mock/MockERC20.sol";

contract FundraisingFactoryTest is Test {
    FundraisingFactory public factory;
    MockERC20 public platformToken;

    address public owner;
    address public user1;
    address public user2;

    uint256 public startDate;
    uint256 public endDate;

    event RequestSubmitted(
        uint256 indexed requestId,
        address indexed creator,
        uint256 tokenTargetMinAmount,
        uint256 tokenTargetMaxAmount,
        uint256 startDate,
        uint256 endDate
    );

    event RequestReviewed(uint256 indexed requestId, bool approved);
    event CampaignCreated(uint256 indexed requestId, address indexed campaignAddress);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);
        platformToken = new MockERC20("Platform Token", "PTK");
        factory = new FundraisingFactory(address(platformToken));
        vm.stopPrank();

        startDate = block.timestamp + 1 days;
        endDate = block.timestamp + 10 days;
    }

    function test_Constructor() public {
        assertEq(factory.owner(), owner);
        assertEq(address(factory.platformToken()), address(platformToken));
    }

    function test_SubmitCampaignRequest() public {
        vm.startPrank(user1);

        vm.expectEmit(true, true, false, true);
        emit RequestSubmitted(0, user1, 100e18, 1000e18, startDate, endDate);

        uint256 requestId = factory.submitCampaignRequest(100e18, 1000e18, startDate, endDate);

        FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestId);

        assertEq(details.creator, user1);
        assertEq(details.tokenTargetMinAmount, 100e18);
        assertEq(details.tokenTargetMaxAmount, 1000e18);
        assertEq(details.startDate, startDate);
        assertEq(details.endDate, endDate);
        assertEq(uint256(details.status), uint256(FundraisingFactory.RequestStatus.Pending));
        assertEq(details.campaignAddress, address(0));

        vm.stopPrank();
    }

    function testFail_SubmitCampaignRequest_InvalidDates() public {
        vm.prank(user1);
        factory.submitCampaignRequest(
            100e18,
            1000e18,
            block.timestamp - 1, // Past start date
            endDate
        );
    }

    function testFail_SubmitCampaignRequest_InvalidAmounts() public {
        vm.prank(user1);
        factory.submitCampaignRequest(
            1000e18, // Min greater than max
            100e18,
            startDate,
            endDate
        );
    }

    function test_ReviewCampaignRequest_Approve() public {
        // Submit request
        vm.prank(user1);
        uint256 requestId = factory.submitCampaignRequest(100e18, 1000e18, startDate, endDate);

        // Approve request
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, true);
        emit RequestReviewed(requestId, true);

        factory.reviewCampaignRequest(requestId, true);

        FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestId);

        assertEq(uint256(details.status), uint256(FundraisingFactory.RequestStatus.Accepted));
        assertTrue(details.campaignAddress != address(0));

        vm.stopPrank();
    }

    function test_ReviewCampaignRequest_Reject() public {
        // Submit request
        vm.prank(user1);
        uint256 requestId = factory.submitCampaignRequest(100e18, 1000e18, startDate, endDate);

        // Reject request
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, true);
        emit RequestReviewed(requestId, false);

        factory.reviewCampaignRequest(requestId, false);

        FundraisingFactory.CampaignRequestDetails memory details = factory.getCampaignRequest(requestId);

        assertEq(uint256(details.status), uint256(FundraisingFactory.RequestStatus.Rejected));
        assertEq(details.campaignAddress, address(0));

        vm.stopPrank();
    }

    function testFail_ReviewCampaignRequest_NotOwner() public {
        vm.prank(user1);
        uint256 requestId = factory.submitCampaignRequest(100e18, 1000e18, startDate, endDate);

        vm.prank(user2);
        factory.reviewCampaignRequest(requestId, true);
    }

    function testFail_ReviewCampaignRequest_AlreadyReviewed() public {
        vm.prank(user1);
        uint256 requestId = factory.submitCampaignRequest(100e18, 1000e18, startDate, endDate);

        vm.startPrank(owner);
        factory.reviewCampaignRequest(requestId, true);
        factory.reviewCampaignRequest(requestId, false); // Should fail
        vm.stopPrank();
    }

    function test_GetCreatorRequests() public {
        vm.startPrank(user1);

        uint256 requestId1 = factory.submitCampaignRequest(100e18, 1000e18, startDate, endDate);
        uint256 requestId2 = factory.submitCampaignRequest(200e18, 2000e18, startDate, endDate);

        uint256[] memory requests = factory.getCreatorRequests(user1);

        assertEq(requests.length, 2);
        assertEq(requests[0], requestId1);
        assertEq(requests[1], requestId2);

        vm.stopPrank();
    }

    function test_TransferOwnership() public {
        vm.startPrank(owner);

        // Capture l'état initial
        address oldOwner = factory.owner();

        factory.transferOwnership(user1);

        // Vérifier que le changement a bien eu lieu
        assertEq(factory.owner(), user1);
        assertFalse(oldOwner == factory.owner());

        vm.stopPrank();
    }

    function testFail_ReviewCampaignRequest_PendingOnly() public {
        vm.prank(user1);
        uint256 requestId = factory.submitCampaignRequest(100e18, 1000e18, startDate, endDate);

        vm.startPrank(owner);
        factory.reviewCampaignRequest(requestId, true); // Première revue
        factory.reviewCampaignRequest(requestId, true); // Devrait échouer car déjà revu
        vm.stopPrank();
    }

    function testFail_SubmitCampaignRequest_EndDateBeforeStart() public {
        vm.prank(user1);
        factory.submitCampaignRequest(
            100e18,
            1000e18,
            block.timestamp + 2 days,
            block.timestamp + 1 days // endDate avant startDate
        );
    }

    function testFail_TransferOwnership_NotOwner() public {
        vm.prank(user1);
        factory.transferOwnership(user2);
    }

    function testFail_TransferOwnership_ZeroAddress() public {
        vm.prank(owner);
        factory.transferOwnership(address(0));
    }

    function testFail_GetCampaignRequest_InvalidId() public view {
        factory.getCampaignRequest(999);
    }

    function testFail_ReviewCampaignRequest_InvalidId() public {
        vm.prank(owner);
        factory.reviewCampaignRequest(999, true);
    }

    function testFail_Constructor_ZeroAddress() public {
        new FundraisingFactory(address(0));
    }
}
