// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRestrictedWritableInternal {
    error PresaleWritable_NoPaymentTokenUpdate();
    error PresaleWritable_ProjectTokenPrice_ZERO();
    error PresaleWritable_SummedMaxTagCapGtGrandTotal(uint256 greaterBy);
}
