// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address) {
        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        uint256 snEscrowAddress = vm.envUint("SN_ESCROW_ADDRESS");
        uint256 snWithdrawSelector = vm.envUint("SN_WITHDRAW_SELECTOR");
        vm.startBroadcast();

        YABTransfer yab = new YABTransfer();
        ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
        YABTransfer(address(proxy)).initialize(snMessagingAddress, snEscrowAddress, snWithdrawSelector);

        vm.stopBroadcast();

        return address(proxy);
    }
}
