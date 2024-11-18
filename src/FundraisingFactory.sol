// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFundraisingFactory.sol";
import "./FundraisingCampaign.sol";

/**
 * @title FundraisingFactory
 * @dev Contract for managing fundraising campaign requests and deployments
 */
contract FundraisingFactory is IFundraisingFactory, Ownable {
    using SafeERC20 for IERC20;

    // State variables
    IERC20 public immutable override platformToken;
    uint256 public override requestCounter;

    // Mappings
    mapping(uint256 => CampaignRequest) public requests;
    mapping(address => uint256[]) public creatorRequests;
    mapping(uint256 => address) public requestToCampaign;

    /**
     * @dev Constructor sets the platform token address
     * @param _platformToken Address of the platform token
     */
    constructor(address _platformToken) Ownable(msg.sender) {
        require(_platformToken != address(0), "Invalid token address");
        platformToken = IERC20(_platformToken);
    }

    /**
     * @dev Submit a new campaign request
     * @param _tokenTargetMinAmount Minimum amount of tokens to raise
     * @param _tokenTargetMaxAmount Maximum amount of tokens to raise
     * @param _startDate Start date of the campaign
     * @param _endDate End date of the campaign
     * @return requestId ID of the new request
     */
    function submitCampaignRequest(
        uint256 _tokenTargetMinAmount,
        uint256 _tokenTargetMaxAmount,
        uint256 _startDate,
        uint256 _endDate
    ) external override returns (uint256) {
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

    /**
     * @dev Review a campaign request and create a new campaign if approved
     * @param _requestId ID of the request to review
     * @param _approved Boolean indicating whether the request is approved
     */
    function reviewCampaignRequest(uint256 _requestId, bool _approved) external override onlyOwner {
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

    /**
     * @dev Get details of a campaign request
     * @param _requestId ID of the request
     * @return details Campaign request details
     */
    function getCampaignRequest(uint256 _requestId)
        external
        view
        override
        returns (CampaignRequestDetails memory details)
    {
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

    /**
     * @dev Get all campaign requests submitted by a creator
     * @param _creator Address of the creator
     * @return requestIds Array of request IDs
     */
    function getCreatorRequests(address _creator) external view override returns (uint256[] memory) {
        return creatorRequests[_creator];
    }
}
