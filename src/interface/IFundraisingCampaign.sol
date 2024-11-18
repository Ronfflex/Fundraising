// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IFundraisingCampaign
 * @notice Interface for the FundraisingCampaign contract
 */
interface IFundraisingCampaign {
    // Events
    event ContributionReceived(
        address indexed contributor, address indexed token, uint256 amount, uint256 platformTokenAmount
    );
    event FundsClaimed(address indexed creator, uint256 amount);
    event RefundProcessed(address indexed contributor, uint256 amount);
    event CampaignEnded(bool successful, uint256 totalCollected);

    // View Functions
    function owner() external view returns (address);
    function creator() external view returns (address);
    function tokenTargetMinAmount() external view returns (uint256);
    function tokenTargetMaxAmount() external view returns (uint256);
    function startDate() external view returns (uint256);
    function endDate() external view returns (uint256);
    function platformToken() external view returns (IERC20);
    function totalCollected() external view returns (uint256);
    function claimed() external view returns (bool);
    function contributions(address contributor) external view returns (uint256);

    // Main Functions
    function contribute(uint256 _amount, IERC20 _contributionToken) external;

    function claimFunds() external;

    function refund() external;

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
        );
}
