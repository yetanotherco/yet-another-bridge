// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract YABTransfer is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct TransferInfo {
        uint256 destAddress;
        uint256 amount;
        bool isUsed;
    }

    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);

    mapping(bytes32 => TransferInfo) public transfers;
    address private _owner;
    IStarknetMessaging private _snMessaging;
    uint256 private _snEscrowAddress;
    uint256 private _snEscrowWithdrawSelector;

    constructor() {
        _disableInitializers();
    }

    // no constructors can be used in upgradeable contracts. 
    function initialize(
        address snMessaging,
        uint256 snEscrowAddress,
        uint256 snEscrowWithdrawSelector) public initializer { 
        _owner = msg.sender;
        __Ownable_init(_owner); //sets owner to msg.sender
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _snEscrowAddress = snEscrowAddress;
        _snEscrowWithdrawSelector = snEscrowWithdrawSelector;
    }

    function transfer(uint256 orderId, uint256 destAddress, uint256 amount) external payable {
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value == amount, "Invalid amount, should match msg.value.");

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        require(transfers[index].isUsed == false, "Transfer already processed.");

        transfers[index] = TransferInfo({destAddress: destAddress, amount: amount, isUsed: true});

        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value}("");

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, transfers[index]);
    }

    function withdraw(uint256 orderId, uint256 destAddress, uint256 amount) external payable {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");

        uint256[] memory payload = new uint256[](5);
        payload[0] = orderId;
        payload[1] = 0;
        payload[2] = transferInfo.destAddress;
        payload[3] = transferInfo.amount;
        payload[4] = 0;
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowWithdrawSelector,
            payload);
    }

    function setEscrowAddress(uint256 snEscrowAddress) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _snEscrowAddress = snEscrowAddress;
    }

    function setEscrowWithdrawSelector(uint256 snEscrowWithdrawSelector) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _snEscrowWithdrawSelector = snEscrowWithdrawSelector;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
