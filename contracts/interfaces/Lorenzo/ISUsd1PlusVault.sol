// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISUsd1PlusVault {
    function directDeposit(address underlyingToken, uint256 underlyingAmount) external;
    function getCurrentUnitNav() external view returns (uint256);
}