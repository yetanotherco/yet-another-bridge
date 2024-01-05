// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {YABTransferV2} from "../src/YABTransferV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Upgrade is Script {
    function run() external returns (address) {
        uint256 YABTrasnferProxyAddress = vm.envUint("ETH_YAB_PROXY_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        YABTransferV2 newYabTransfer = new YABTransferV2();
        vm.stopBroadcast();
        address proxy = upgradeYABTransfer(address(uint160(uint(keccak256(abi.encodePacked(YABTrasnferProxyAddress))))), address(newYabTransfer));
        return proxy;
    }

    function upgradeYABTransfer(address proxyAddress, address newYABTrasnfer) public returns (address) {

        YABTransfer proxy = YABTransfer(payable(proxyAddress));

        address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x0;

        proxy.upgradeToAndCall(newYABTrasnfer, 
            abi.encode()
);
        
        vm.stopBroadcast();
        return address(proxy);
    }
}