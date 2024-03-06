// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PaymentRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct TransferInfo {
        uint256 destAddress; //cant lower size since SN address is uint256
        uint256 amount; //cant lower size since msg.value is uint256
        bool isUsed;
    }

    //changing to uint32 is more expensive
    //srcAddress is for explorer, dont remove
    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);
    event ModifiedEscrowAddress(uint256 newEscrowAddress);
    event ModifiedEscrowClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);

    mapping(bytes32 => TransferInfo) private transfers;
    address private _marketMaker;
    IStarknetMessaging private _snMessaging;
    uint256 private _snEscrowAddress;
    uint256 private _snEscrowClaimPaymentSelector;

    constructor() {
        _disableInitializers();
    }

    // no constructors can be used in upgradeable contracts. 
    function initialize(
        address snMessaging,
        uint256 snEscrowAddress,
        uint256 snEscrowClaimPaymentSelector,
        address marketMaker) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _snEscrowAddress = snEscrowAddress;
        _snEscrowClaimPaymentSelector = snEscrowClaimPaymentSelector; //recieving from param is cheaper
        _marketMaker = marketMaker;
    }


    // changed removed amount param
    function transfer(uint256 orderId, uint256 destAddress) external payable onlyOwnerOrMM {
        require(destAddress != 0, "t1");
        require(msg.value > 0, "t2");

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, msg.value));
        require(transfers[index].isUsed == false, "t3");

        transfers[index] = TransferInfo({destAddress: destAddress, amount: msg.value, isUsed: true});

        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value}("");

        require(success, "t4");
        emit Transfer(orderId, msg.sender, transfers[index]);
    }

    function claimPayment(uint256 orderId, uint256 destAddress, uint256 amount) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "c1");

        uint128[] memory payload = new uint128[](5);
        payload[0] = uint128(orderId); // low
        payload[1] = uint128(orderId >> 128); // high
        payload[2] = transferInfo.destAddress;
        payload[3] = uint128(amount); // low
        payload[4] = uint128(amount >> 128); // high

        // //todo check in integration test if it works
        // uint256[] memory payload = new uint256[](3);
        // payload[0] = orderId; //unlucky waste of space
        // // payload[1] = uint128(orderId >> 128); // high
        // payload[1] = transferInfo.destAddress;
        // payload[2] = amount; // low
        // // payload[4] = uint128(amount >> 128); // high
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowClaimPaymentSelector,
            payload);
    }

    function setEscrowAddress(uint256 snEscrowAddress) external onlyOwner {
        _snEscrowAddress = snEscrowAddress;
        emit ModifiedEscrowAddress(snEscrowAddress);        
    }

    function setEscrowClaimPaymentSelector(uint256 snEscrowClaimPaymentSelector) external onlyOwner {
        _snEscrowClaimPaymentSelector = snEscrowClaimPaymentSelector;
        emit ModifiedEscrowClaimPaymentSelector(snEscrowClaimPaymentSelector);
    }

    function getEscrowAddress() external view returns (uint256) {
        return _snEscrowAddress;
    }

    function getEscrowClaimPaymentSelector() external view returns (uint256) {
        return _snEscrowClaimPaymentSelector;
    }
    
    
    //// MM ACL:

    function getMMAddress() external view returns (address) {
        return _marketMaker;
    }

    function setMMAddress(address newMMAddress) external onlyOwner {
        _marketMaker = newMMAddress;
    }

    modifier onlyOwnerOrMM {
        require(msg.sender == owner() || msg.sender == _marketMaker, "o1");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
