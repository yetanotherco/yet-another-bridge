// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UriCoin is ERC20 {
    constructor() ERC20("UriCoin", "Uri") {
        _mint(0xda963fA72caC2A3aC01c642062fba3C099993D56, 1000000); //TODO unhardcode recipient + initial_supply
    }
}
