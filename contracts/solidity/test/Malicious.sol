// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PaymentRegistry} from "../src/PaymentRegistry.sol";

contract Malicious is Initializable {

    IStarknetMessaging private _snMessaging;
    uint256 private _snEscrowAddress;
    uint256 private _snEscrowClaimPaymentSelector;

    PaymentRegistry public myPaymentRegistry;

    constructor(
        address snMessaging,
        uint256 snEscrowAddress,
        uint256 snEscrowClaimPaymentSelector,
        address ethPaymentRegistryAddress) {

        _snMessaging = IStarknetMessaging(snMessaging);
        _snEscrowAddress = snEscrowAddress;
        _snEscrowClaimPaymentSelector = snEscrowClaimPaymentSelector;
        myPaymentRegistry = PaymentRegistry(ethPaymentRegistryAddress);
    }

    function steal_from_escrow(uint256 orderId, uint256 destAddress, uint256 amount) external payable {
        uint256[] memory payload = new uint256[](5);

        payload[0] = uint128(orderId); // low
        payload[1] = uint128(orderId >> 128); // high
        payload[2] = destAddress;
        payload[3] = uint128(amount); // low
        payload[4] = uint128(amount >> 128); // high
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowClaimPaymentSelector,
            payload);
    }

    function steal_from_PaymentRegistry(uint256 orderId, uint256 destAddress, uint256 amount) external payable {
        myPaymentRegistry.claimPayment(orderId, destAddress, amount);
    }

    function setEscrowAddress(uint256 snEscrowAddress) external {
        _snEscrowAddress = snEscrowAddress;
    }

    function setEscrowClaimPaymentSelector(uint256 snEscrowClaimPaymentSelector) external {
        _snEscrowClaimPaymentSelector = snEscrowClaimPaymentSelector;
    }

    function getEscrowAddress() external view returns (uint256) {
        return _snEscrowAddress;
    }

    function getEscrowClaimPaymentSelector() external view returns (uint256) {
        return _snEscrowClaimPaymentSelector;
    }
}
