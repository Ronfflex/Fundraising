// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./FundraisingCampaign.sol";

/**
 * @title FundraisingFactory
 * @dev Contract for managing fundraising campaign requests and deployments
 */
contract FundraisingFactory {
    using SafeERC20 for IERC20;

    // State variables
    address public owner;
    IERC20 public immutable platformToken;
    uint256 public requestCounter;

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

    enum RequestStatus {
        Pending,
        Accepted,
        Rejected
    }

    // Mappings
    mapping(uint256 => CampaignRequest) public requests;
    mapping(address => uint256[]) public creatorRequests;
    mapping(uint256 => address) public requestToCampaign;

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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _platformToken) {
        require(_platformToken != address(0), "Invalid token address");
        owner = msg.sender;
        platformToken = IERC20(_platformToken);
    }

    function submitCampaignRequest(
        uint256 _tokenTargetMinAmount,
        uint256 _tokenTargetMaxAmount,
        uint256 _startDate,
        uint256 _endDate
    ) external returns (uint256) {
        require(_tokenTargetMaxAmount > _tokenTargetMinAmount, "Max amount must be greater than min");
        require(_startDate > block.timestamp, "Start date must be in the future");
        require(_endDate > _startDate, "End date must be after start date");

        uint256 requestId = requestCounter++;

        requests[requestId] = CampaignRequest({
            creator: msg.sender,
            tokenTargetMinAmount: _tokenTargetMinAmount,
            tokenTargetMaxAmount: _tokenTargetMaxAmount,
            startDate: _startDate,
            endDate: _endDate,
            status: RequestStatus.Pending
        });

        creatorRequests[msg.sender].push(requestId);

        emit RequestSubmitted(requestId, msg.sender, _tokenTargetMinAmount, _tokenTargetMaxAmount, _startDate, _endDate);

        return requestId;
    }

    function reviewCampaignRequest(uint256 _requestId, bool _approved) external onlyOwner {
        require(_requestId < requestCounter, "Invalid request ID");
        CampaignRequest storage request = requests[_requestId];
        require(request.status == RequestStatus.Pending, "Request not pending");

        if (_approved) {
            request.status = RequestStatus.Accepted;
            address campaign = address(
                new FundraisingCampaign(
                    request.creator,
                    request.tokenTargetMinAmount,
                    request.tokenTargetMaxAmount,
                    request.startDate,
                    request.endDate,
                    address(platformToken)
                )
            );
            requestToCampaign[_requestId] = campaign;
            emit CampaignCreated(_requestId, campaign);
        } else {
            request.status = RequestStatus.Rejected;
        }

        emit RequestReviewed(_requestId, _approved);
    }

    function getCampaignRequest(uint256 _requestId) external view returns (CampaignRequestDetails memory details) {
        require(_requestId < requestCounter, "Invalid request ID");
        CampaignRequest storage request = requests[_requestId];

        return CampaignRequestDetails({
            creator: request.creator,
            tokenTargetMinAmount: request.tokenTargetMinAmount,
            tokenTargetMaxAmount: request.tokenTargetMaxAmount,
            startDate: request.startDate,
            endDate: request.endDate,
            status: request.status,
            campaignAddress: requestToCampaign[_requestId]
        });
    }

    function getCreatorRequests(address _creator) external view returns (uint256[] memory) {
        return creatorRequests[_creator];
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
