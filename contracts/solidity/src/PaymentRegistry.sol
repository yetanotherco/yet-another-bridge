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
    event Transfer(uint256 orderId, address srcAddress, TransferInfo transferInfo);
    
    //changed removed unnecesarry Events. Their new values can be getted with their getters
    // for now these 2 events are not necesarry since we are the only Market Makers
    // event ModifiedEscrowAddress(uint256 newEscrowAddress);
    // event ModifiedEscrowClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);

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
        //changed removed following require:
        // require(destAddress != 0, "t1");
        //todo maybe remove this check as well:
        require(msg.value >= 1, "t2"); //changed ">=" is cheaper than ">"

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, msg.value));
        require(transfers[index].isUsed == false, "t3"); //acts as reentrancy guard

        transfers[index] = TransferInfo({destAddress: destAddress, amount: msg.value, isUsed: true});

        //todo following call is 30k expensive, try to make it cheaper
        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value, gas: 700}("");
        // (bool success) = payable(address(uint160(destAddress))).send(msg.value); //700 gas cheaper, todo is it safe?
        
        require(success, "t4");

        emit Transfer(orderId, msg.sender, transfers[index]);
    }

    function claimPayment(uint256 orderId, uint256 destAddress, uint256 amount) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "c1");

        uint256[] memory payload = new uint256[](3);
        payload[0] = uint256(orderId);
        payload[1] = uint256(transferInfo.destAddress);
        payload[2] = uint256(amount);
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowClaimPaymentSelector,
            payload);
    }

    function setEscrowAddress(uint256 snEscrowAddress) external onlyOwner {
        _snEscrowAddress = snEscrowAddress;
        // emit ModifiedEscrowAddress(snEscrowAddress);        
    }

    function setEscrowClaimPaymentSelector(uint256 snEscrowClaimPaymentSelector) external onlyOwner {
        _snEscrowClaimPaymentSelector = snEscrowClaimPaymentSelector;
        // emit ModifiedEscrowClaimPaymentSelector(snEscrowClaimPaymentSelector);
    }

    //private vars with getters are cheaper than public vars
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
