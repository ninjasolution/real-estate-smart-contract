// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISharedInternal {
    enum Status {
        NOT_STARTED,
        OPENED,
        COMPLETED,
        PAUSED
    }

    struct Tag {
        Status status;
        // contains wallet and allocation per wallet
        uint128 startAt;
        uint128 endAt;
        uint256 maxTagCap;
        uint256 minAllocation;
        uint256 maxAllocation;
        uint256 allocation;
        uint256 maxParticipants;
    }
}
