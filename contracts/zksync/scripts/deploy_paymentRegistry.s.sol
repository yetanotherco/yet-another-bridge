// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PaymentRegistry} from "../src/PaymentRegistry.sol";
// import {PaymentRegistry} from "../src/PaymentRegistry.sol";
// import {PaymentRegistry} from "/Users/urix/yet-another-bridge/contracts/ethereum/src/PaymentRegistry.sol";
// import {ERC1967Proxy} from "../../ethereum/lib/openzeppelin-contracts-upgradeable/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address, address) {
        uint256 deployerPrivateKey = 0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110; //prefunded
        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        uint256 snEscrowAddress = 0x0; // this value is set in a call to the smart contract, once deployed
        uint256 snClaimPaymentSelector = 0x0; // this value is set in a call to the smart contract, once deployed
        address marketMaker = vm.envAddress("MM_ETHEREUM_WALLET");
        address ZKSYNC_MAILBOX_ADDRESS = vm.envAddress("ZKSYNC_MAILBOX_ADDRESS");

        // PaymentRegistry yab = new PaymentRegistry();
        // ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
        // PaymentRegistry(address(proxy)).initialize(snMessagingAddress, snEscrowAddress, snClaimPaymentSelector, marketMaker, ZKSYNC_MAILBOX_ADDRESS);

        ERC1967Proxy proxy = new ERC1967Proxy(address(0x0), "");

        vm.stopBroadcast();

        // return (address(proxy), address(yab));
        return (address(proxy), address(0x0));
    }
}
