// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStandardBridge} from "optimism/IStandardBridge.sol";
import {IChainTransfer} from "interfaces/IChainTransfer.sol";

contract OptimismTransfer is IChainTransfer {
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

        IStandardBridge opL1Bridge = IStandardBridge(address(uint160(_addresses["opL1BridgeAddress"])));
        
        uint32 minGasLimit = 200000;
        opL1Bridge.bridgeETHTo{value: msg.value}(
            address(uint160(destAddress)),
            minGasLimit, 
            new bytes(0x0));
    }

    function withdraw(uint256[] calldata payload) external payable { }

    function setOpL1BridgeAddress(uint256 opL1BridgeAddress) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _addresses["opL1BridgeAddress"] = opL1BridgeAddress;
    }
}
