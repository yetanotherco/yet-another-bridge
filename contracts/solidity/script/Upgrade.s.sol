// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "../lib/forge-std/src/console.sol";
import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {YABTransferV2} from "../src/YABTransferV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Upgrade is Script {
    function run() external returns (address) {
        address YABTrasnferProxyAddress = vm.envAddress("ETH_YAB_PROXY_ADDRESS");
        vm.startBroadcast();

        YABTransferV2 transferV2 = new YABTransferV2();
        console.log("YABTrasnferProxyAddress", address(YABTrasnferProxyAddress));
        console.log("TransferV2 ", address(transferV2));
        vm.stopBroadcast();

        address proxy = upgradeAddy(YABTrasnferProxyAddress, address(transferV2)); //upgrades contractA to contractB
        return proxy;
    }


    function upgradeAddy(
        address proxyAddress,
        address newAddy
    ) public returns (address) {
        vm.startBroadcast();

        YABTransfer proxy = YABTransfer(payable(proxyAddress)); //we want to make a function call on this address
        proxy.upgradeToAndCall(address(newAddy), ''); 
    
        //proxy address now points to this new address
        vm.stopBroadcast();
        return address(proxy);
    }

}