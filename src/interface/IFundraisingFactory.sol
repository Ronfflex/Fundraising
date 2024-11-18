// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IFundraisingFactory
 * @notice Interface for the FundraisingFactory contract
 */
interface IFundraisingFactory {
    // Enums
    enum RequestStatus {
        Pending,
        Accepted,
        Rejected
    }

    // Structs
    struct CampaignRequest {
        address creator;
        uint256 tokenTargetMinAmount;
        uint256 tokenTargetMaxAmount;
        uint256 startDate;
        uint256 endDate;
        RequestStatus status;
    }

    struct CampaignRequestDetails {
        address creator;
        uint256 tokenTargetMinAmount;
        uint256 tokenTargetMaxAmount;
        uint256 startDate;
        uint256 endDate;
        RequestStatus status;
        address campaignAddress;
    }

    // Events
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

    // Functions
    function platformToken() external view returns (IERC20);
    function requestCounter() external view returns (uint256);

    function submitCampaignRequest(
        uint256 _tokenTargetMinAmount,
        uint256 _tokenTargetMaxAmount,
        uint256 _startDate,
        uint256 _endDate
    ) external returns (uint256);

    function reviewCampaignRequest(uint256 _requestId, bool _approved) external;

    function getCampaignRequest(uint256 _requestId) external view returns (CampaignRequestDetails memory details);

    function getCreatorRequests(address _creator) external view returns (uint256[] memory);
}
