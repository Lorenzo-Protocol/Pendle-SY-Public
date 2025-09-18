// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISUsd1PlusReward {
    function claimRewards(address account) external returns (uint256);
    function getRewardToken() external view returns (address);
}