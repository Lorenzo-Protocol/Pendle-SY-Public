// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../../interfaces/Lorenzo/ISUsd1PlusReward.sol";

contract PendleLorenzoSUsd1PlusReward is UUPSUpgradeable, OwnableUpgradeable, ISUsd1PlusReward {

    // Events
    event SetClaimer(address indexed claimer, bool isClaimer);
    event ReleaseReward(address indexed claimer, uint256 amount, uint32 releaseTime);
    event ClaimReward(address indexed claimer, uint256 amount, uint32 claimedTime);

    // Errors
    error InvalidClaimer(address claimer);
    error InvalidAmount(uint256 amount);

    // Modifiers
    modifier onlyClaimer() {
        if (!claimers[msg.sender]) {
            revert InvalidClaimer(msg.sender);
        }
        _;
    }

    // Constants
    IERC20 public immutable rewardToken;

    // State Variables
    struct RewardState {
        uint256 pendingAmount;     // total pending reward
        uint256 releasedAmount;    // total released reward
        uint32  lastClaimedTime;  // last claimed block
        uint32  lastReleaseTime;  // last released block
    }

    // [claimer] => bool
    mapping(address => bool) public claimers;
    // [claimer] => RewardState
    mapping(address => RewardState) public rewardState;

// ------------------------------
// Constructor
// ------------------------------
    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function initialize(address _owner) external initializer {
        require(_owner != address(0), "zero owner");

        __Ownable_init();
        __UUPSUpgradeable_init();

        _transferOwnership(_owner);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // @dev set the claimer
    // @param claimer the claimer address
    // @param isClaimer whether the claimer is a claimer or not
    function setClaimer(address claimer, bool isClaimer) external onlyOwner {
        if (claimer == address(0)) {
            revert InvalidClaimer(claimer);
        }

        claimers[claimer] = isClaimer;

        emit SetClaimer(claimer, isClaimer);
    }

    // @dev release the rewards from the SY
    // @param claimer the claimer address
    // @param amount the amount of rewards to release
    function releaseRewards(address claimer, uint256 amount) external onlyOwner {
        if (claimer == address(0)) {
            revert InvalidClaimer(claimer);
        }

        if (amount == 0) {
            revert InvalidAmount(amount);
        }

        rewardState[claimer].pendingAmount  += amount;
        rewardState[claimer].releasedAmount += amount;
        rewardState[claimer].lastReleaseTime = uint32(block.timestamp);

        emit ReleaseReward(claimer, amount, uint32(block.timestamp));
    }

    // @dev claim the rewards from the SY.
    // if there is no pending rewards, just return 0 but not transfer  any token.
    // @param claimer the claimer address
    function claimRewards(address claimer) external override onlyClaimer returns (uint256) {
        if (rewardState[claimer].pendingAmount == 0) return 0;

        uint256 amount = rewardState[claimer].pendingAmount;
        rewardState[claimer].pendingAmount = 0;
        rewardState[claimer].lastClaimedTime = uint32(block.timestamp);

        SafeERC20.safeTransfer(rewardToken, claimer, amount);

        emit ClaimReward(claimer, amount, uint32(block.timestamp));

        return amount;
    }

    // @dev get the reward token
    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }
}