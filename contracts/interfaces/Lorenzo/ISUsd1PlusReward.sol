// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ISUsd1PlusReward {
    function claimRewards(address account) external returns (uint256);
    function rewardToken() external view returns (IERC20);
}