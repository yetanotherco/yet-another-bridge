// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address) {
        // uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast();


        YABTransfer yab = new YABTransfer();
        ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
        YABTransfer(address(proxy)).initialize(0xde29d060D45901Fb19ED6C6e959EB22d8626708e, 0x0, 0x0);

        vm.stopBroadcast();

        return address(proxy);
    }
}
