// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        uint256 snWithdrawSelector = 0x0;
        uint256 snEscrowAddress = 0x0;

        YABTransfer yab = new YABTransfer();
        ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
        YABTransfer(address(proxy)).initialize(snMessagingAddress, snEscrowAddress, snWithdrawSelector);

        vm.stopBroadcast();

        return address(proxy);
    }
}
