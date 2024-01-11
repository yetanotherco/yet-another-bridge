// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/YABTransfer.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        uint256 snEscrowAddress = 0x0; //this value is set in a call to the smart contract, once deployed
        uint256 snEscrowWithdrawSelector = 0x0; //this value is set in a call to the smart contract, once deployed


        new YABTransfer(
            snMessagingAddress,
            snEscrowAddress,
            snEscrowWithdrawSelector);

        vm.stopBroadcast();
    }
}
