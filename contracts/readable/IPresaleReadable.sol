// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISharedInternal} from "../shared/ISharedInternal.sol";

interface IPresaleReadable {
    /**
     * @return Allocation amount reserved by the account in a tag, expressed
     *         in PresaleStruct.SetUp.paymentToken OR Tag.paymentToken
     */
    function allocationReservedByIn(
        address account,
        string calldata tagId
    ) external view returns (uint256);

    function presaleStatus() external view returns (ISharedInternal.Status);

    function raisedInTag(string memory tagId) external view returns (uint256);

    function setUp()
        external
        view
        returns (
            address vestingContract,
            address paymentToken,
            uint256 grandTotal,
            uint256 summedMaxTagCap,
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 refundFee
        );

    function tag(
        string memory tagId
    ) external view returns (ISharedInternal.Tag memory tag_);

    function participants(
        string memory tagId
    ) external view returns (uint256 count) ;

    function investment(
        string memory tagId,
        address account
    ) external view returns (uint256 amount) ;

    function tagIds() external view returns (string[] memory tagIds_);

    function totalRaised() external view returns (uint256);
}
