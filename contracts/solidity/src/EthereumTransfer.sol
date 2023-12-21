// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IChainTransfer} from "interfaces/IChainTransfer.sol";

contract EthereumTransfer is IChainTransfer {
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

    function withdraw(uint256[] calldata payload) external payable { }
}
