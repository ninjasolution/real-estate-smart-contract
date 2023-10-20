// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IPresaleReadable} from "../readable/IPresaleReadable.sol";
import {IRestrictedWritableInternal} from "../writable/restricted/IRestrictedWritableInternal.sol";
import {ISharedInternal} from "../shared/ISharedInternal.sol";
import {IPresaleWritableInternal} from "../writable/IPresaleWritableInternal.sol";

import {PresaleStorage} from "../PresaleStorage.sol";

contract PresaleReadable is
    IPresaleReadable,
    IPresaleWritableInternal,
    IRestrictedWritableInternal,
    ISharedInternal
{
    /// @inheritdoc IPresaleReadable
    function allocationReservedByIn(
        address account,
        string calldata tagId
    ) external view override returns (uint256) {
        return
            PresaleStorage.layout().ledger.allocationReservedByIn[account][tagId];
    }

    function presaleStatus() external view override returns (Status) {
        return PresaleStorage.layout().ledger.status;
    }

    function raisedInTag(
        string memory tagId
    ) external view override returns (uint256) {
        return PresaleStorage.layout().ledger.raisedInTag[tagId];
    }

    function setUp()
        external
        view
        override
        returns (
            address vestingContract,
            address paymentToken,
            uint256 grandTotal,
            uint256 summedMaxTagCap,
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 refundFee
        )
    {
        PresaleStorage.SetUp memory setUp_ = PresaleStorage.layout().setUp;
        vestingContract = setUp_.vestingContract;
        paymentToken = setUp_.paymentToken;
        grandTotal = setUp_.grandTotal;
        summedMaxTagCap = setUp_.summedMaxTagCap;
        minAllocation = setUp_.minAllocation;
        maxAllocation = setUp_.maxAllocation;
        refundFee = setUp_.refundFee;
    }

    function tag(
        string memory tagId
    ) external view override returns (Tag memory tag_) {
        tag_ = PresaleStorage.layout().tags.data[tagId];
    }

    function participants(
        string memory tagId
    ) external view override returns (uint256 count) {
        count = PresaleStorage.layout().ledger.participantsInTag[tagId];
    }

    function investment(
        string memory tagId,
        address account
    ) external view override returns (uint256 amount) {
        amount = PresaleStorage.layout().ledger.investmentInTag[tagId][account];
    }

    function tagIds()
        external
        view
        override
        returns (string[] memory tagIds_)
    {
        tagIds_ = PresaleStorage.layout().tags.ids;
    }

    function totalRaised() external view override returns (uint256) {
        return PresaleStorage.layout().ledger.totalRaised;
    }
}
