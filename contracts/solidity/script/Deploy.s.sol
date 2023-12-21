// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/YABTransfer.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256 snMessagingAddress = uint256(uint160(0xde29d060D45901Fb19ED6C6e959EB22d8626708e));
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x0;
        uint256 opL1BridgeAddress = uint256(uint160(0x636Af16bf2f682dD3109e60102b8E1A089FedAa8));

        YABTransfer yab = new YABTransfer();
        yab.setSnMessagingAddress(snMessagingAddress);
        yab.setSnEscrowAddress(snEscrowAddress);
        yab.setSnEscrowWithdrawSelector(snEscrowWithdrawSelector);
        yab.setOpL1BridgeAddress(opL1BridgeAddress);
        // call sets for each

        vm.stopBroadcast();
    }
}
