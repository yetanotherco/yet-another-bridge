// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {Malicious} from "../test/Malicious.sol";
// import  {Deploy} from "Deploy.s.sol";

contract DeployMalicious is Script {
    function run() external returns (address, address) {

        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        uint256 snEscrowAddress = vm.envAddress("ESCROW_CONTRACT_ADDRESS"); //check if it works
        uint256 snClaimPaymentSelector = vm.envAddress("CLAIM_PAYMENT_SELECTOR"); //check if it works

        Malicious malicious = new Malicious(snMessagingAddress, snEscrowAddress, snClaimPaymentSelector);

        vm.stopBroadcast();
        return (address(malicious));
    }
}


//         PaymentRegistry yab = new PaymentRegistry();
//         ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
//         PaymentRegistry(address(proxy)).initialize(snMessagingAddress, snEscrowAddress, snClaimPaymentSelector, marketMaker);
//return