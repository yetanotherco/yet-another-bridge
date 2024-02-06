// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {PaymentRegistry} from "../src/PaymentRegistry.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address, address) {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address snMessagingAddress = vm.envAddress("SN_MESSAGING_ADDRESS");
        uint256 snEscrowAddress = 0x0; // this value is set in a call to the smart contract, once deployed
        uint256 snWithdrawSelector = 0x0; // this value is set in a call to the smart contract, once deployed
        address marketMaker = vm.envAddress("MM_ETHEREUM_WALLET");

        PaymentRegistry yab = new PaymentRegistry();
        ERC1967Proxy proxy = new ERC1967Proxy(address(yab), "");
        PaymentRegistry(address(proxy)).initialize(snMessagingAddress, snEscrowAddress, snWithdrawSelector, marketMaker);

        vm.stopBroadcast();

        return (address(proxy), address(yab));
    }
}
