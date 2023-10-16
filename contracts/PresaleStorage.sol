// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISharedInternal} from "./shared/ISharedInternal.sol";

library PresaleStorage {
    // Only updated by owner
    struct SetUp {
        address vestingContract;
        address paymentToken;
        // maximum amount of paymentToken that can be raised
        uint256 grandTotal;
        // sum of maxTagCap OF all existing tags, can be lower than
        // `grandTotal` and maximum equal to `grandTotal`
        uint256 summedMaxTagCap;
        uint256 refundFeeDecimals;
    }

    // Updated by owner and users interactions
    struct Tags {
        string[] ids;
        mapping(string => ISharedInternal.Tag) data;
    }

    // Only updated by users interactions
    struct Ledger {
        ISharedInternal.Status status;
        uint256 totalRaised;
        mapping(string => uint256) raisedInTag;
        mapping(string => uint256) participantsInTag;
        mapping(string => mapping (address => uint256)) investmentInTag;
        mapping(address => mapping(string => uint256)) allocationReservedByIn;
    }

    struct PresaleStruct {
        SetUp setUp;
        Tags tags;
        Ledger ledger;
    }

    bytes32 public constant Presale_STORAGE = keccak256("presale.storage");

    function layout() internal pure returns (PresaleStruct storage presaleStruct) {
        bytes32 position = Presale_STORAGE;
        assembly ("memory-safe") {
            presaleStruct.slot := position
        }
    }
}
