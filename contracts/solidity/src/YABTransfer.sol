// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {IStandardBridge} from "optimism/IStandardBridge.sol";
import {IChainTransfer} from "interfaces/IChainTransfer.sol";

contract YABTransfer {
    struct TransferInfo {
        uint256 originChain;
        uint256 destinationChain;
        uint256 orderId;
        uint256 destAddress;
        uint256 amount;
        bool isUsed;
    }

    event Transfer(bytes32 indexed index, address srcAddress, TransferInfo transferInfo);

    mapping(bytes32 => TransferInfo) public transfers;
    mapping(uint256 => address) private _chainAddresses;

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }
    
    function transfer(
        uint256 originChain,
        uint256 destinationChain,
        uint256 orderId,
        uint256 destAddress,
        uint256 amount) external payable {
        require(_chainAddresses[originChain] != address(0), "Origin chain address not set.");
        require(_chainAddresses[destinationChain] != address(0), "Destination chain address not set.");
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value > amount, "Invalid amount, should be lower than msg.value.");

        bytes32 index = keccak256(abi.encodePacked(originChain, destinationChain, orderId, destAddress, amount));
        require(transfers[index].isUsed == false, "Transfer already processed.");

        transfers[index] = TransferInfo({
            originChain: originChain,
            destinationChain: destinationChain,
            orderId: orderId,
            destAddress: destAddress,
            amount: amount,
            isUsed: true
        });

        (bool success,) = _chainAddresses[destinationChain].call{value: msg.value}(abi.encodeWithSelector(
            IChainTransfer.transfer.selector,
            destAddress,
            amount));

        require(success, "Transfer failed.");
        emit Transfer(index, msg.sender, transfers[index]);
    }

    function withdraw(
        uint256 originChain,
        uint256 destinationChain,
        uint256 orderId,
        uint256 destAddress,
        uint256 amount) external payable {
        bytes32 index = keccak256(abi.encodePacked(originChain, destinationChain, orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");

        uint256[] memory payload = new uint256[](5);
        payload[0] = originChain;
        payload[1] = destinationChain;
        payload[2] = orderId;
        payload[3] = destAddress;
        payload[4] = amount;

        (bool success,) = _chainAddresses[originChain].call(abi.encodeWithSelector(
            IChainTransfer.withdraw.selector,
            destAddress,
            amount,
            payload));

        require(success, "Withdraw failed.");
    }

    function setChainAddress(
        uint256 chainId,
        address chainAddress) external {
        require(msg.sender == _owner, "Only owner can set chain address.");
        _chainAddresses[chainId] = chainAddress;
    }

}
