// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISharedInternal} from "../shared/ISharedInternal.sol";

interface IPresaleWritableInternal {
    struct Allocation {
        string tagId;
        address account;
        // maximum amount the user can spend, expressed in PresaleStruct.SetUp.paymentToken
        uint256 maxAllocation;
        // take PresaleStorage.PresaleStruct.SetUp.refundFeeDecimals into account
        uint256 refundFee;
        // price per token of the project behind the Presale, expressed in
        // `PresaleSTorage.SetUp.paymentToken` (any ERC20)
        uint256 presaleTokenPerPaymentToken;
    }

    event AllocationReserved(
        string indexed tagId,
        address indexed buyer,
        uint256 indexed maxAllocation,
        address paymentToken
    );

    error PresaleWritableInternal_PresaleNotOpened(ISharedInternal.Status current);
    error PresaleWritableInternal_TagNotOpened(
        string tagId,
        ISharedInternal.Status current
    );
    error PresaleWritable_AllocationExceeded(
        uint256 allocation,
        uint256 exceedsBy
    );
    error PresaleWritable_MaxTagCapExceeded(
        string tagId,
        uint256 maxTagCap,
        uint256 exceedsBy
    );
    error PresaleWritable_MaxParticipantsExceeded(
        string tagId,
        uint256 maxParticipants
    );
    error PresaleWritable_GrandTotalExceeded(
        uint256 grandTotal,
        uint256 exceedsBy
    );
}
