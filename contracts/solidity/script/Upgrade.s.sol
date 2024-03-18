// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {console} from "../lib/forge-std/src/console.sol";
import {Script} from "forge-std/Script.sol";
import {PaymentRegistry} from "../src/PaymentRegistry.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Upgrade is Script {
    function run() external returns (address, address) {
        address PaymentRegistryProxyAddress = vm.envAddress("PAYMENT_REGISTRY_PROXY_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("ETHEREUM_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy new PaymentRegistry contract to upgrade proxy
        PaymentRegistry yab = new PaymentRegistry();
        vm.stopBroadcast();

        return upgrade(PaymentRegistryProxyAddress, address(yab));
    }

    function upgrade(
        address proxyAddress,
        address newImplementationAddress
    ) public returns (address, address) {
        uint256 deployerPrivateKey = vm.envUint("ETHEREUM_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        PaymentRegistry proxy = PaymentRegistry(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newImplementationAddress), ''); 
    
        vm.stopBroadcast();
        return (address(proxy), address(newImplementationAddress));

    }

}
