// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PaymentRegistry} from "../src/PaymentRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address, address) {
        uint256 deployerPrivateKey = vm.envUint("ETHEREUM_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = vm.envAddress("STARKNET_MESSAGING_ADDRESS");
        uint256 snEscrowAddress = 0x0; // this value is set in a call to the smart contract, once deployed
        uint256 snClaimPaymentSelector = 0x0; // this value is set in a call to the smart contract, once deployed
        uint256 snClaimPaymentBatchSelector = 0x0; // this value is set in a call to the smart contract, once deployed
        address marketMaker = vm.envAddress("MM_ETHEREUM_WALLET_ADDRESS");
        address ZKSYNC_DIAMOND_PROXY_ADDRESS = vm.envAddress("ZKSYNC_DIAMOND_PROXY_ADDRESS");

        PaymentRegistry yab = new PaymentRegistry();
        ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
        PaymentRegistry(address(proxy)).initialize(
            snMessagingAddress, 
            snEscrowAddress, 
            snClaimPaymentSelector, 
            snClaimPaymentBatchSelector, 
            marketMaker,
            ZKSYNC_DIAMOND_PROXY_ADDRESS
        );
        vm.stopBroadcast();

        return (address(proxy), address(yab));
    }
}
