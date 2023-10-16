// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import {ISharedInternal} from "../../shared/ISharedInternal.sol";
import {IRestrictedWritable} from "./IRestrictedWritable.sol";

import {PresaleStorage} from "../../PresaleStorage.sol";

import {RestrictedWritableInternal} from "./RestrictedWritableInternal.sol";

/**
 * @dev Inherits from `ISharedInternal` will create `error[5005]: Linearization of inheritance graph impossible`
 */
contract RestrictedWritable is
    IRestrictedWritable,
    RestrictedWritableInternal,
    AccessControlEnumerable
{
    using SafeERC20 for IERC20;

    function openPresale() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        PresaleStorage.layout().ledger.status = ISharedInternal.Status.OPENED;
    }

    function pausePresale() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        PresaleStorage.layout().ledger.status = ISharedInternal.Status.PAUSED;
    }

    function updateGrandTotal(
        uint256 grandTotal_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(grandTotal_ >= 1_000, "grandTotal_LowerThan__1_000");
        _isSummedMaxTagCapLteGrandTotal(
            PresaleStorage.layout().setUp.summedMaxTagCap,
            grandTotal_
        );
        PresaleStorage.layout().setUp.grandTotal = grandTotal_;
    }

    /// @inheritdoc IRestrictedWritable
    function recoverLostERC20(
        address token,
        address to
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(0), "Token_ZERO_ADDRESS");
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, amount);
    }

    //////////////////////////// TAG BATCH UPDATES ////////////////////////////
    /// @inheritdoc IRestrictedWritable
    function updateSetTag(
        string calldata tagId_,
        ISharedInternal.Tag calldata tag_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        ISharedInternal.Tag memory oldTagData = PresaleStorage.layout().tags.data[
            tagId_
        ];
        require(_notEmptyTag(tag_), "EMPTY_TAG");

        PresaleStorage.layout().setUp.summedMaxTagCap = _setTag(
            PresaleStorage.layout().setUp.grandTotal,
            PresaleStorage.layout().setUp.summedMaxTagCap,
            oldTagData.maxTagCap,
            tag_,
            tagId_
        );
    }

    /// @inheritdoc IRestrictedWritable
    function updateSetTags(
        string[] calldata tagIdentifiers_,
        ISharedInternal.Tag[] calldata tags_
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTags(tagIdentifiers_, tags_);
    }

    //////////////////////////// TAG SINGLE UPDATE ////////////////////////////
    function openTag(
        string calldata tagId
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        PresaleStorage.layout().tags.data[tagId].status = ISharedInternal
            .Status
            .OPENED;
    }

    function pauseTag(
        string calldata tagId
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        PresaleStorage.layout().tags.data[tagId].status = ISharedInternal
            .Status
            .PAUSED;
    }

    function updateTagMerkleRoot(
        string calldata tagId,
        bytes32 merkleRoot
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(merkleRoot != bytes32(0), "MerkleRoot_EMPTY");
        PresaleStorage.layout().tags.data[tagId].merkleRoot = merkleRoot;
    }

    function updateTagStartDate(
        string calldata tagId,
        uint128 startAt
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(startAt >= block.timestamp, "START_IN_PAST");
        PresaleStorage.layout().tags.data[tagId].startAt = startAt;
    }

    function updateTagEndDate(
        string calldata tagId,
        uint128 endAt
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(endAt > block.timestamp, "END_IN_PAST");
        PresaleStorage.layout().tags.data[tagId].endAt = endAt;
    }

    function updateTagMaxCap(
        string calldata tagId,
        uint256 maxTagCap
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        PresaleStorage.SetUp memory setUp = PresaleStorage.layout().setUp;
        uint256 summedMaxTagCap = setUp.summedMaxTagCap;

        summedMaxTagCap -= PresaleStorage.layout().tags.data[tagId].maxTagCap;
        summedMaxTagCap += maxTagCap;

        _isSummedMaxTagCapLteGrandTotal(summedMaxTagCap, setUp.grandTotal);
        PresaleStorage.layout().tags.data[tagId].maxTagCap = maxTagCap;
    }
}
