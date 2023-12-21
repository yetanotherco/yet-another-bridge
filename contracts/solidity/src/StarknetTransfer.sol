// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {IChainTransfer} from "interfaces/IChainTransfer.sol";

contract StarknetTransfer is IChainTransfer {
    mapping(bytes32 => uint256) private _addresses;
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function transfer(
        uint256 destAddress,
        uint256 amount) external payable {
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value > amount, "Invalid amount, should be lower than msg.value.");

        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value}("");

        require(success, "Transfer failed.");
    }

    function withdraw(uint256[] calldata payload) external payable {
        IStarknetMessaging snMessaging = IStarknetMessaging(address(uint160(_addresses["snMessagingAddress"])));

        // Repack for Starknet
        uint256[] memory payloadProcessed = new uint256[](7);

        // u256
        payloadProcessed[0] = payload[0];
        payloadProcessed[1] = 0;
        // u256
        payloadProcessed[2] = payload[1];
        payloadProcessed[3] = 0;
        // u256
        payloadProcessed[4] = payload[2];
        payloadProcessed[5] = 0;
        // felt252
        payloadProcessed[6] = payload[3];
        // u256
        payloadProcessed[7] = payload[4];
        payloadProcessed[8] = 0;

        snMessaging.sendMessageToL2{value: msg.value}(
            _addresses["snEscrowAddress"],
            _addresses["snEscrowWithdrawSelector"],
            payloadProcessed);
    }

    function setSnMessagingAddress(uint256 snMessagingAddress) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _addresses["snMessagingAddress"] = snMessagingAddress;
    }

    function setSnEscrowAddress(uint256 snEscrowAddress) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _addresses["snEscrowAddress"] = snEscrowAddress;
    }

    function setSnEscrowWithdrawSelector(uint256 snEscrowWithdrawSelector) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _addresses["snEscrowWithdrawSelector"] = snEscrowWithdrawSelector;
    }
}
