// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILinearVesting {

    struct ContractSetup {
        address paymentReceiver;
        address admin;
        address vestedToken;
        uint256 platformFee;
        uint256 totalTokenOnSale;
        uint256 gracePeriod;
        uint256 decimals;
    }

    struct VestingSetup {
        uint256 startTime;
        uint256 cliff;
        uint256 duration;
        uint256 initialUnlockPercent;
    }

    function initializeCrowdfunding(ContractSetup memory contractSetup, VestingSetup memory vestingSetup) external;
    function setCrowdfundingWhitelist(string memory tagId, address account, uint256 amount, address paymentToken, uint256 amount1, uint256 refundFee) external;
    function getToken() external view returns (address);
}