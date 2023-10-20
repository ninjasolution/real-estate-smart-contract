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
        uint128 presaleTokenPerPaymentToken;
        uint128 startAt;
        uint128 endAt;
        uint256 maxTagCap;
        uint256 allocation;
        uint256 maxParticipants;
    }
}
