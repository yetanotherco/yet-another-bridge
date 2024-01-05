// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {YABTransferV2} from "../src/YABTransferV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Upgrade is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        uint256 YABTrasnferProxyAddress = vm.envUint("ETH_YAB_PROXY_ADDRESS");
        address deployerAddress = vm.addr(deployerPrivateKey);
 
        // console.log("Deployer address: ", deployerAddress);
        // console.log("Deployer balance: ", deployerAddress.balance);
        // console.log("BlockNumber: ", block.number);
        // console.log("ChainId: ", getChain());
        
        // console.log("Deploying new implementation...");

        vm.startBroadcast(deployerPrivateKey);

        YABTransferV2 transferV2 = new YABTransferV2();

        // console.log("Deployed new implementation: ", address(transferV2));

        UUPSUpgradeable proxy = UUPSUpgradeable(address(uint160(uint(keccak256(abi.encodePacked(YABTrasnferProxyAddress))))));
        proxy.upgradeToAndCall(address(transferV2), abi.encode());

        // console.log(
        //     "Proxy implementation updated. Proxy: ",
        //     address(proxy),
        //     " implementation:",
        //     address(transferV2)
        // );
        vm.stopBroadcast();
        // YABTransfer proxy = YABTransfer(payable(proxyAddress));
        // YABTransferV2 newYabTransfer = new YABTransferV2();
        // vm.stopBroadcast();
        // address proxy = upgradeYABTransfer(address(uint160(uint(keccak256(abi.encodePacked(YABTrasnferProxyAddress))))), address(newYabTransfer));
        // return proxy;
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