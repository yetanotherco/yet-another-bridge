// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract UriCoin is ERC20 {
//     constructor() ERC20("UriCoin", "Uri") {
//         _mint(0xB321099cf86D9BB913b891441B014c03a6CcFc54, 1000000); //hardcoded recipient + initial_supply
//     }
// }

contract UriCoin is ERC20 {
    constructor(address initial_whale, uint256 initial_supply) ERC20("UriCoin", "Uri") {
        _mint(initial_whale, initial_supply); //hardcoded recipient + initial_supply
    }
}