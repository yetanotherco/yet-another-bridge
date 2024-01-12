// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "../lib/forge-std/src/console.sol";
import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Upgrade is Script {
    function run() external returns (address) {
        address YABTrasnferProxyAddress = vm.envAddress("YAB_TRANSFER_PROXY_ADDRESS");
        vm.startBroadcast();

        // Deploy new YABTransfer contract to upgrade proxy
        YABTransfer yab = new YABTransfer();
        vm.stopBroadcast();

        address proxy = upgrade(YABTrasnferProxyAddress, address(yab));
        return proxy;
    }

    function upgrade(
        address proxyAddress,
        address newImplementationAddress
    ) public returns (address) {
        vm.startBroadcast();

        YABTransfer proxy = YABTransfer(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newImplementationAddress), ''); 
    
        vm.stopBroadcast();
        return address(proxy);
    }

}
