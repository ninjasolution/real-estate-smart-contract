// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISharedInternal} from "../../shared/ISharedInternal.sol";

/// @notice Only the owner of the contract can call these methods.
interface IRestrictedWritable {
    //////////////////////////// SHARED Presale DATA ////////////////////////////
    function openPresale() external;

    function pausePresale() external;

    function updateGrandTotal(uint256 grandTotal_) external;

    /// @dev Retrieve any ERC20 sent to the contract by mistake.
    function recoverLostERC20(address token, address to) external;

    //////////////////////////// TAG BATCH UPDATES ////////////////////////////
    /// @dev Update a tag and all its data.
    function updateSetTag(
        string calldata tagId_,
        ISharedInternal.Tag calldata tag_
    ) external;

    /**
     * @dev If a tag with an identifier already exists, it will be
     *      updated, otherwise it will be created.
     */
    function updateSetTags(
        string[] calldata tagIdentifiers_,
        ISharedInternal.Tag[] calldata tags_
    ) external;

    // TODO: UX choice to make here, do we need both tag single field update and tag batch update?
    //////////////////////////// TAG SINGLE UPDATE ////////////////////////////
    function openTag(string calldata tagId) external;

    function pauseTag(string calldata tagId) external;

    function updateTagMerkleRoot(
        string calldata tagId,
        bytes32 merkleRoot
    ) external;

    function updateTagStartDate(
        string calldata tagId,
        uint128 startAt
    ) external;

    function updateTagEndDate(string calldata tagId, uint128 endAt) external;

    function updateTagMaxCap(
        string calldata tagId,
        uint256 maxTagCap
    ) external;
}
