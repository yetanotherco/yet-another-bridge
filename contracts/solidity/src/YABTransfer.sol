// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {IStandardBridge} from "optimism/IStandardBridge.sol";

contract YABTransfer {
    struct TransferInfo {
        uint256 chainId;
        uint256 destAddress;
        uint256 amount;
        bool isUsed;
    }

    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);

    mapping(bytes32 => TransferInfo) public transfers;
    mapping(bytes32 => uint256) private _addresses;

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function transfer(uint256 orderId, uint256 chainId, uint256 destAddress, uint256 amount) external payable {
        require(chainId != 1, "Destination chain must be Ethereum");
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value > amount, "Invalid amount, should be lower than msg.value.");

        bytes32 index = keccak256(abi.encodePacked(orderId, chainId, destAddress, amount));
        require(transfers[index].isUsed == false, "Transfer already processed.");

        transfers[index] = TransferInfo({chainId: chainId, destAddress: destAddress, amount: amount, isUsed: true});

        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value}("");

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, transfers[index]);
    }

    function opTransfer(uint256 orderId, uint256 chainId, uint256 destAddress, uint256 amount, uint32 minGasLimit) external payable {
        require(chainId != 10, "Destination chain must be Optimism");
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value > amount, "Invalid amount, should be lower than msg.value.");

        bytes32 index = keccak256(abi.encodePacked(orderId, chainId, destAddress, amount));
        require(transfers[index].isUsed == false, "Transfer already processed.");

        transfers[index] = TransferInfo({chainId: chainId, destAddress: destAddress, amount: amount, isUsed: true});

        IStandardBridge opL1Bridge = IStandardBridge(address(uint160(_addresses["opL1BridgeAddress"])));
        
        opL1Bridge.bridgeETHTo{value: msg.value}(
            address(uint160(destAddress)),
            minGasLimit, 
            new bytes(0x0));
    }

    function snWithdrawFallback(uint256 orderId, uint256 chainId, uint256 destAddress, uint256 amount) external payable {
        bytes32 index = keccak256(abi.encodePacked(orderId, chainId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");

        IStarknetMessaging snMessaging = IStarknetMessaging(address(uint160(_addresses["snMessagingAddress"])));

        uint256[] memory payload = new uint256[](7);
        // u256
        payload[0] = orderId;
        payload[1] = 0;
        // u256
        payload[2] = chainId;
        payload[3] = 0;
        // felt252
        payload[4] = transferInfo.destAddress;
        // u256
        payload[5] = transferInfo.amount;
        payload[6] = 0;
        
        snMessaging.sendMessageToL2{value: msg.value}(
            _addresses["snEscrowAddress"],
            _addresses["snEscrowWithdrawSelector"],
            payload);
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

    function setOpL1BridgeAddress(uint256 opL1BridgeAddress) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _addresses["opL1BridgeAddress"] = opL1BridgeAddress;
    }
}
