// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {YABTransfer} from "../src/YABTransfer.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address, address) {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        uint256 snEscrowAddress = 0x0; // this value is set in a call to the smart contract, once deployed
        uint256 snWithdrawSelector = 0x0; // this value is set in a call to the smart contract, once deployed
        address MarketMaker = 0xda963fA72caC2A3aC01c642062fba3C099993D56;//vm.envAddress("MM_ETHEREUM_WALLET");

        YABTransfer yab = new YABTransfer();
        ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
        YABTransfer(address(proxy)).initialize(snMessagingAddress, snEscrowAddress, snWithdrawSelector, MarketMaker);

        vm.stopBroadcast();

        return (address(proxy), address(yab));
    }
}
