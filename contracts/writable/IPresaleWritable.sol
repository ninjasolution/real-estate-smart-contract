// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IPresaleWritableInternal} from "./IPresaleWritableInternal.sol";
import {ISharedInternal} from "../shared/ISharedInternal.sol";

import {PresaleStorage} from "../PresaleStorage.sol";

interface IPresaleWritable {
    /**
     * @param amount Amount of tokens to buy in this transaction, expressed in PresaleStorgae.SetUp.paymentToken.
     * @param allocation Allocation reserved to a specfic tag for a wallet.
     */
    function reserveAllocation(
        uint256 amount,
        IPresaleWritableInternal.Allocation calldata allocation
    ) external;

    function initialize(
        address owner,
        PresaleStorage.SetUp calldata setUp,
        string[] calldata tagIds_,
        ISharedInternal.Tag[] calldata tags
    ) external;
}
