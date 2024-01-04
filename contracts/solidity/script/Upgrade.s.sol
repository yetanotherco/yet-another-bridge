// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UpgradesScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // example deployment and upgrade of a UUPS proxy
        address uupsProxy = Upgrades.deployUUPSProxy(
            "GreeterProxiable.sol",
            abi.encodeCall(GreeterProxiable.initialize, ("hello"))
        );
        Upgrades.upgradeProxy(
            uupsProxy,
            "GreeterV2Proxiable.sol",
            abi.encodeCall(GreeterV2Proxiable.resetGreeting, ())
        );

        // example deployment of a beacon proxy and upgrade of the beacon
        address beacon = Upgrades.deployBeacon("Greeter.sol", msg.sender);
        Upgrades.deployBeaconProxy(beacon, abi.encodeCall(Greeter.initialize, ("hello")));
        Upgrades.upgradeBeacon(beacon, "GreeterV2.sol");

        vm.stopBroadcast();
    }
}

//      function run() public {
//         uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
//         uint256 proxyAdminAddress = vm.envUint("ETH_PROXY_ADMIN_ADDRESS");
//         uint256 proxyUpgradeableAddress = vm.envUint("ETH_PROXY_UPGRADEABLE_ADDRESS");

//         vm.startBroadcast(deployerPrivateKey);

//         address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
//         uint256 snEscrowAddress = 0x0;
//         uint256 snEscrowWithdrawSelector = 0x0;

//         YABTransfer yab = new YABTransfer(
//             snMessagingAddress,
//             snEscrowAddress,
//             snEscrowWithdrawSelector);

//         ITransparentUpgradeableProxy proxyUpgradeable = ITransparentUpgradeableProxy(address(uint160(proxyUpgradeableAddress)));
//         ProxyAdmin(address(uint160(proxyAdminAddress))).upgradeAndCall(proxyUpgradeable, address(yab), "");
//         vm.stopBroadcast();
//     }