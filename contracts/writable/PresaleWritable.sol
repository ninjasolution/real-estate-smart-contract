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
        string calldata tagId,
        uint256 amount
    ) external override nonReentrant {
        // `Allocation` struct data in local variables (save gas)
        // local variables (save gas)
        ISharedInternal.Tag memory tag = PresaleStorage.layout().tags.data[tagId];
        PresaleStorage.SetUp memory setUp = PresaleStorage.layout().setUp;

        require(setUp.minAllocation <= amount, "Less than minimum allocation");
        require(setUp.maxAllocation >= amount, "Exceed than tag maximum allocation");

        uint256 maxTagCap = tag.maxTagCap;
        uint256 grandTotal = setUp.grandTotal;

        // check given parameters
        _requireAllocationNotExceededInTag(
            amount,
            msg.sender,
            setUp.maxAllocation,
            tagId
        );

        _requireAuthorizedAccount(msg.sender);
        _requireGrandTotalNotExceeded(amount, grandTotal);
        _requireOpenedPresale();
        _requireOpenedTag(tagId);
        _requireTagParticipantsNotExceeded(tagId, tag.maxParticipants);
        _requireTagCapNotExceeded(tagId, maxTagCap, amount);

        _updateStorageOnBuy(
            amount,
            tagId,
            msg.sender,
            grandTotal,
            maxTagCap
        );

        ILinearVesting(setUp.vestingContract).setCrowdfundingWhitelist(
            tagId,
            msg.sender,
            amount,
            setUp.paymentToken,
            // calculate the amount of presale tokens to be received
            tag.price,
            setUp.refundFee
        );

       _reserveAllocation(setUp, amount);

        emit AllocationReserved(
            tagId,
            msg.sender,
            amount,
            setUp.paymentToken
        );
    }

    function initialize(
        address owner,
        PresaleStorage.SetUp memory setUp,
        string[] calldata tagIds_,
        ISharedInternal.Tag[] calldata tags
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
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
