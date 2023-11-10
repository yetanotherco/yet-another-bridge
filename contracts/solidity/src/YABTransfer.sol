// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

contract YABTransfer {
    struct TransferInfo {
        uint256 destAddress;
        uint256 amount;
        bool isUsed;
    }

    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);

    mapping(uint256 => TransferInfo) public transfers;

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
}
