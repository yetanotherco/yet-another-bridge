// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";

contract YABTransfer {
    struct TransferInfo {
        uint256 destAddress;
        uint256 amount;
        bool isUsed;
    }

    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);

    mapping(uint256 => TransferInfo) public transfers;
    IStarknetMessaging private _snMessaging;
    uint256 private _snEscrowAddress;
    uint256 private _snEscrowWithdrawSelector;

    constructor(
        address snMessaging,
        uint256 snEscrowAddress,
        uint256 snEscrowWithdrawSelector) {
        _snMessaging = IStarknetMessaging(snMessaging);
        _snEscrowAddress = snEscrowAddress;
        _snEscrowWithdrawSelector = snEscrowWithdrawSelector;
    }

    function transfer(uint256 orderId, uint256 destAddress, uint256 amount) external payable {
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value == amount, "Invalid amount, should match msg.value.");
        require(transfers[orderId].isUsed == false, "Transfer already processed.");

        transfers[orderId] = TransferInfo({destAddress: destAddress, amount: amount, isUsed: true});

        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value}("");

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, transfers[orderId]);
    }

    function withdraw(uint256 orderId) external payable {
        TransferInfo storage transferInfo = transfers[orderId];
        require(transferInfo.isUsed == true, "Transfer not found.");

        uint256[] memory payload = new uint256[](3);
        payload[0] = orderId;
        payload[1] = transferInfo.destAddress;
        payload[2] = transferInfo.amount;
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowWithdrawSelector,
            payload);
    }
}
