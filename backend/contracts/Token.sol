// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    // initialising contract with 1 Million tokens minted to 
    // the creator of the contract 
    constructor() ERC20("Token", "$TKN") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

