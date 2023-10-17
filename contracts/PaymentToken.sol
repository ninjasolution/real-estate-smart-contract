// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";


contract PaymentToken is ERC20, Ownable {
    constructor() ERC20("Payment Token", "PTC") {
        _mint(msg.sender, (700_000_000 * 10 ** 18));

    }
}
