// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISUsd1PlusVault {
    function deposit(address underlyingToken, uint256 underlyingAmount) external payable;
    function getCurrentUnitNav() external view returns (uint256);
}