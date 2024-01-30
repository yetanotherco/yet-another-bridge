// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

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
    address private _marketMaker;
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
        uint256 snEscrowWithdrawSelector,
        address marketMaker) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _snEscrowAddress = snEscrowAddress;
        _snEscrowWithdrawSelector = snEscrowWithdrawSelector;
        _marketMaker = marketMaker;
    }


    function transfer(uint256 orderId, uint256 destAddress, uint256 amount) external payable onlyOwnerOrMM {
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

    function withdraw(uint256 orderId, uint256 destAddress, uint256 amount) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");

        uint256[] memory payload = new uint256[](5);
        payload[0] = uint128(orderId); // low
        payload[1] = uint128(orderId >> 128); // high
        payload[2] = transferInfo.destAddress;
        payload[3] = uint128(amount); // low
        payload[4] = uint128(amount >> 128); // high
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowWithdrawSelector,
            payload);
    }

    function setEscrowAddress(uint256 snEscrowAddress) external onlyOwner {
        _snEscrowAddress = snEscrowAddress;
    }

    function setEscrowWithdrawSelector(uint256 snEscrowWithdrawSelector) external onlyOwner {
        _snEscrowWithdrawSelector = snEscrowWithdrawSelector;
    }

    
    //// MM ACL:

    function getMMAddress() external view returns (address) {
        return _marketMaker;
    }

    function setMMAddress(address newMMAddress) external onlyOwner {
        _marketMaker = newMMAddress;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    modifier onlyOwnerOrMM {
        require(msg.sender == owner() || msg.sender == _marketMaker, "Only Owner or MM can call this function");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
