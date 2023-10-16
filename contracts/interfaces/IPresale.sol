// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPresale {
    function getInvestment(address user) external view returns (uint256);
}