// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

contract YABTransfer {
    struct TransferInfo {
        uint256 destAddress;
        uint128 amount;
    }

    event Transfer(
        uint256 indexed transferId,
        address srcAddress,
        TransferInfo transferInfo);

    uint256 public currentTransferId = 0;

    mapping(uint256 => TransferInfo) public transfers;

    function transfer(
        TransferInfo calldata transferInfo
    ) payable external {
        require(transferInfo.destAddress != 0, "Invalid destination address.");
        require(transferInfo.amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value == transferInfo.amount, "Invalid amount, should match msg.value.");

        transfers[currentTransferId] = transferInfo;
        currentTransferId += 1;

        (bool success, ) = payable(transferInfo.destAddress).call{value: msg.value}("");

        require(success, "Transfer failed.");
        emit Transfer(currentTransferId, msg.sender, transferInfo);
    }
}
