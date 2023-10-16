// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ILinearVesting} from "../LinearVesting.sol";
import {IPresaleWritable} from "./IPresaleWritable.sol";
import {ISharedInternal} from "../shared/ISharedInternal.sol";
import {PresaleStorage} from "../PresaleStorage.sol";
import {RestrictedWritable} from "./restricted/RestrictedWritable.sol";
import {PresaleWritableInternal} from "./PresaleWritableInternal.sol";

contract PresaleWritable is
    Initializable,
    IPresaleWritable,
    PresaleWritableInternal,
    RestrictedWritable,
    ReentrancyGuard
{
    /// @inheritdoc IPresaleWritable
    function reserveAllocation(
        uint256 amount,
        Allocation calldata allocation
    ) external override nonReentrant {
        // `Allocation` struct data in local variables (save gas)
        // local variables (save gas)
        ISharedInternal.Tag memory tag = PresaleStorage.layout().tags.data[
            allocation.tagId
        ];
        PresaleStorage.SetUp memory setUp = PresaleStorage.layout().setUp;

        require(tag.minAllocation <= amount, "Less than minimum allocation");
        require(allocation.maxAllocation >= amount, "Exceed than granted maximum allocation");
        require(tag.maxAllocation >= amount, "Exceed than tag maximum allocation");

        uint256 maxTagCap = tag.maxTagCap;
        uint256 grandTotal = setUp.grandTotal;

        // check given parameters
        _requireAllocationNotExceededInTag(
            amount,
            allocation.account,
            allocation.maxAllocation,
            allocation.tagId
        );

        _requireAuthorizedAccount(allocation.account);
        _requireGrandTotalNotExceeded(amount, grandTotal);
        _requireOpenedPresale();
        _requireOpenedTag(allocation.tagId);
        _requireTagParticipantsNotExceeded(allocation.tagId, tag.maxParticipants);
        _requireTagCapNotExceeded(allocation.tagId, maxTagCap, amount);

        _updateStorageOnBuy(
            amount,
            allocation.tagId,
            allocation.account,
            grandTotal,
            maxTagCap
        );

        ILinearVesting(setUp.vestingContract).setCrowdfundingWhitelist(
            allocation.tagId,
            allocation.account,
            amount,
            setUp.paymentToken,
            // calculate the amount of presale tokens to be received
            allocation.presaleTokenPerPaymentToken,
            allocation.refundFee
        );

       _reserveAllocation(setUp, amount);

        emit AllocationReserved(
            allocation.tagId,
            allocation.account,
            amount,
            setUp.paymentToken
        );
    }

    function initialize(
        address owner,
        PresaleStorage.SetUp memory setUp,
        string[] calldata tagIds_,
        ISharedInternal.Tag[] calldata tags
    ) external override initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        require(owner != address(0), "PresaleWritable__owner_ZERO_ADDRESS");

        require(
            setUp.vestingContract != address(0),
            "PresaleWritable__vestingContract_ZERO_ADDRESS"
        );
        require(
            setUp.paymentToken != address(0),
            "PresaleWritable__paymentToken_ZERO_ADDRESS"
        );
        
        require(setUp.grandTotal > 0, "PresaleWritable__grandTotal_ZERO");

        _grantRole(DEFAULT_ADMIN_ROLE, owner);

        PresaleStorage.layout().setUp = setUp;

        _setTags(tagIds_, tags);
    }
}
