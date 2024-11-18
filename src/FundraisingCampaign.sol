// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title FundraisingCampaign
 * @dev Contract for managing individual fundraising campaigns
 */
contract FundraisingCampaign is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    address public immutable owner;
    address public immutable creator;
    uint256 public immutable tokenTargetMinAmount;
    uint256 public immutable tokenTargetMaxAmount;
    uint256 public immutable startDate;
    uint256 public immutable endDate;
    IERC20 public immutable platformToken;

    uint256 public totalCollected;
    bool public claimed;
    mapping(address => uint256) public contributions;

    // Events
    event ContributionReceived(address indexed contributor, address indexed token, uint256 amount, uint256 platformTokenAmount);
    event FundsClaimed(address indexed creator, uint256 amount);
    event RefundProcessed(address indexed contributor, uint256 amount);
    event CampaignEnded(bool successful, uint256 totalCollected);

    /**
     * @dev Constructor sets all campaign parameters
     */
    constructor(
        address _creator,
        uint256 _tokenTargetMinAmount,
        uint256 _tokenTargetMaxAmount,
        uint256 _startDate,
        uint256 _endDate,
        address _platformToken
    ) {
        require(_creator != address(0), "Invalid creator address");
        require(_platformToken != address(0), "Invalid token address");
        require(_tokenTargetMaxAmount > _tokenTargetMinAmount, "Invalid target amounts");
        require(_endDate > _startDate, "Invalid dates");

        owner = msg.sender;
        creator = _creator;
        tokenTargetMinAmount = _tokenTargetMinAmount;
        tokenTargetMaxAmount = _tokenTargetMaxAmount;
        startDate = _startDate;
        endDate = _endDate;
        platformToken = IERC20(_platformToken);
    }

    /**
     * @dev Allows contributors to participate in the fundraising
     * @param _amount Amount of tokens to contribute
     * @param _contributionToken ERC20 token used for contribution
     */
    function contribute(uint256 _amount, IERC20 _contributionToken) external nonReentrant {
        require(block.timestamp >= startDate, "Campaign not started");
        require(block.timestamp <= endDate, "Campaign ended");
        require(totalCollected + _amount <= tokenTargetMaxAmount, "Exceeds maximum target");
        require(_amount > 0, "Amount must be greater than 0");
        require(address(_contributionToken) != address(0), "Invalid token address");

        // Update state before transfer
        contributions[msg.sender] += _amount;
        totalCollected += _amount;

        // Transfer contribution tokens to this contract
        _contributionToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit ContributionReceived(msg.sender, address(_contributionToken), _amount, _amount);
    }

    /**
     * @dev Allows creator to claim funds if campaign is successful
     */
    function claimFunds() external nonReentrant {
        require(msg.sender == creator, "Only creator can claim");
        require(!claimed, "Already claimed");
        require(block.timestamp > endDate, "Campaign not ended");
        require(totalCollected >= tokenTargetMinAmount, "Minimum target not reached");

        claimed = true;

        platformToken.safeTransfer(creator, totalCollected);

        emit FundsClaimed(creator, totalCollected);
        emit CampaignEnded(true, totalCollected);
    }

    /**
     * @dev Allows contributors to get refund if campaign fails
     */
    function refund() external nonReentrant {
        require(block.timestamp > endDate, "Campaign not ended");
        require(totalCollected < tokenTargetMinAmount, "Campaign successful");
        
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution found");
        
        // Update state before transfer
        contributions[msg.sender] = 0;

        platformToken.safeTransfer(msg.sender, amount);

        emit RefundProcessed(msg.sender, amount);
    }

    /**
     * @dev Returns all campaign details
     */
    function getCampaignDetails()
        external
        view
        returns (
            address _creator,
            uint256 _tokenTargetMinAmount,
            uint256 _tokenTargetMaxAmount,
            uint256 _startDate,
            uint256 _endDate,
            uint256 _totalCollected,
            bool _claimed,
            bool _isActive,
            bool _isSuccessful
        )
    {
        bool isActive = block.timestamp >= startDate && block.timestamp <= endDate;
        bool isSuccessful = totalCollected >= tokenTargetMinAmount;

        return (
            creator,
            tokenTargetMinAmount,
            tokenTargetMaxAmount,
            startDate,
            endDate,
            totalCollected,
            claimed,
            isActive,
            isSuccessful
        );
    }
}