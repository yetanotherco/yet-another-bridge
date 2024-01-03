// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "../src/YABTransfer.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Upgrade is Script {
    function run() external payable {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        uint256 proxyAddress = vm.envUint("ETH_PROXY_UPGRADEABLE_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
        uint256 snEscrowAddress = 0x0;
        uint256 snEscrowWithdrawSelector = 0x0;

        YABTransfer yab = new YABTransfer(
            snMessagingAddress,
            snEscrowAddress,
            snEscrowWithdrawSelector);

        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(address(uint160(proxyAddress)));
        proxy.upgradeToAndCall(address(yab), "");

        vm.stopBroadcast();
    }
}
