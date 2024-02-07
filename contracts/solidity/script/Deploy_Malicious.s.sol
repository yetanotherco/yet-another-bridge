// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {Malicious} from "../test/Malicious.sol";
// import  {Deploy} from "Deploy.s.sol";
import "forge-std/console.sol";

contract DeployMalicious is Script {
    function run() external returns (address) {

        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        // console.log("snMessagingAddress");
        // console.log(snMessagingAddress);
        uint256 snEscrowAddress = 0x0;//vm.envAddress("ESCROW_CONTRACT_ADDRESS"); //check if it works
        uint256 snClaimPaymentSelector = 0x0;//vm.envAddress("CLAIM_PAYMENT_SELECTOR"); //check if it works
        address PaymentRegistryProxyAddress = vm.envAddress("PAYMENT_REGISTRY_PROXY_ADDRESS");

        Malicious malicious = new Malicious(snMessagingAddress, snEscrowAddress, snClaimPaymentSelector, PaymentRegistryProxyAddress);

        vm.stopBroadcast();
        return (address(malicious));
    }
}