// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BlackGirlCoin is ERC20 {
    constructor() ERC20("BlackGirlCoin", "BGC") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}