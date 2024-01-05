// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/YABTransfer.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
        uint256 snEscrowAddress = 0x0;
            //this is always the same value as long as starknet's function's name is "withdraw"
            //this being the case, the function to overwrite this value should be deprecated
        uint256 snEscrowWithdrawSelector = 0x15511cc3694f64379908437d6d64458dc76d02482052bfb8a5b33a72c054c77;


        new YABTransfer(
            snMessagingAddress,
            snEscrowAddress,
            snEscrowWithdrawSelector);

        vm.stopBroadcast();
    }
}
