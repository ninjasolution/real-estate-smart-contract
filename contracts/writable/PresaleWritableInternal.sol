// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ISharedInternal} from "../shared/ISharedInternal.sol";
import {IPresaleWritableInternal} from "./IPresaleWritableInternal.sol";
import {PresaleStorage} from "../PresaleStorage.sol";

/**
 * @notice Inherits from `ISharedInternal` will create `error[5005]: Linearization of inheritance graph impossible`
 */
contract PresaleWritableInternal is IPresaleWritableInternal {
    /// @dev sends ERC20 from `msg.sender` to vesting schedule
    function _reserveAllocation(
        PresaleStorage.SetUp memory setUp,
        uint256 amount
    ) internal {
        IERC20(setUp.paymentToken).transferFrom(
            msg.sender,
            setUp.vestingContract,
            amount
        );
    }

    function _closePresale() internal {
        PresaleStorage.layout().ledger.status = ISharedInternal.Status.COMPLETED;
    }

    function _closeTag(string memory tagId) internal {
        PresaleStorage.layout().tags.data[tagId].status = ISharedInternal
            .Status
            .COMPLETED;
    }

    function _updateStorageOnBuy(
        uint256 amount,
        string calldata tagId,
        address buyer,
        uint256 grandTotal,
        uint256 maxTagCap
    ) internal {
        PresaleStorage.Ledger storage ledger = PresaleStorage.layout().ledger;

        // update raised amount
        ledger.totalRaised += amount;
        ledger.raisedInTag[tagId] += amount;
        if (ledger.investmentInTag[tagId][buyer] == 0) {
            ledger.participantsInTag[tagId] += 1;
        }
        ledger.investmentInTag[tagId][buyer] += amount;
        ledger.allocationReservedByIn[buyer][tagId] += amount;
        // close if limit reached
        if (ledger.totalRaised == grandTotal) _closePresale();
        if (ledger.raisedInTag[tagId] == maxTagCap) _closeTag(tagId);
        // close if time elapsed
        if (block.timestamp >= PresaleStorage.layout().tags.data[tagId].endAt) {
            _closeTag(tagId);
        }
    }

    /**
     * @dev Ensure a wallet can not more than their allocation for the
     *      given tag.
     */
    function _requireAllocationNotExceededInTag(
        uint256 toBuy,
        address rewardee,
        uint256 allocated,
        string calldata tagId
    ) internal view {
        uint256 totalAfterPurchase = toBuy +
            PresaleStorage.layout().ledger.allocationReservedByIn[rewardee][tagId];
        if (totalAfterPurchase > allocated) {
            revert PresaleWritable_AllocationExceeded(
                allocated,
                totalAfterPurchase - allocated
            );
        }
    }

    /// @dev Only the `msg.sender` can buy tokens for themselves
    function _requireAuthorizedAccount(address account) internal view {
        require(account == msg.sender, "msg.sender: NOT_AUTHORIZED");
    }

    /// @dev verify `grandTotal` will not be exceeded, after purchase
    function _requireGrandTotalNotExceeded(
        uint256 toBuy,
        uint256 grandTotal
    ) internal view {
        uint256 totalAfterPurchase = toBuy +
            PresaleStorage.layout().ledger.totalRaised;
        if (totalAfterPurchase > grandTotal) {
            revert PresaleWritable_GrandTotalExceeded(
                grandTotal,
                totalAfterPurchase - grandTotal
            );
        }
    }

    function _requireOpenedPresale() internal view {
        ISharedInternal.Status current = PresaleStorage.layout().ledger.status;
        if (current != ISharedInternal.Status.OPENED) {
            revert PresaleWritableInternal_PresaleNotOpened(current);
        }
    }

    function _requireOpenedTag(string memory tagId) internal {
        ISharedInternal.Tag memory tag = PresaleStorage.layout().tags.data[tagId];
        // open tag if necessary
        if (
            tag.status == ISharedInternal.Status.NOT_STARTED &&
            block.timestamp >= tag.startAt &&
            block.timestamp < tag.endAt
        ) {
            PresaleStorage.layout().tags.data[tagId].status = ISharedInternal
                .Status
                .OPENED;
            return;
        }
        // revert if tag not opened
        if (tag.status != ISharedInternal.Status.OPENED) {
            revert PresaleWritableInternal_TagNotOpened(tagId, tag.status);
        }
    }

    /// @dev verify `maxTagParticipants` will not be exceeded, after purchase
    function _requireTagParticipantsNotExceeded(
        string calldata tagId,
        uint256 maxParticipants
    ) internal view {
        if (
            maxParticipants <=
            PresaleStorage.layout().ledger.participantsInTag[tagId]
        ) {
            revert PresaleWritable_MaxParticipantsExceeded(tagId, maxParticipants);
        }
    }

    /// @dev verify `maxTagCap` will not be exceeded, after purchase
    function _requireTagCapNotExceeded(
        string calldata tagId,
        uint256 maxTagCap,
        uint256 toBuy
    ) internal view {
        uint256 raisedAfterPurchase = toBuy +
            PresaleStorage.layout().ledger.raisedInTag[tagId];
        if (raisedAfterPurchase > maxTagCap) {
            revert PresaleWritable_MaxTagCapExceeded(
                tagId,
                maxTagCap,
                raisedAfterPurchase - maxTagCap
            );
        }
    }

}
