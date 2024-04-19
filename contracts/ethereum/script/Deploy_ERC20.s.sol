// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {UriCoin} from "../src/ERC20_L1.sol";

contract Deploy is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("ETHEREUM_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UriCoin uriCoin = new UriCoin();

        vm.stopBroadcast();

        return (address(uriCoin));
    }
}
