// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {PresaleStorage} from "./PresaleStorage.sol";

import {PresaleReadable} from "./readable/PresaleReadable.sol";
import {PresaleWritable} from "./writable/PresaleWritable.sol";

contract Presale is PresaleReadable, PresaleWritable {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
