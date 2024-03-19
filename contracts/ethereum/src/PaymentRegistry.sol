// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PaymentRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct TransferInfo {
        uint256 destAddress;
        uint256 amount;
        bool isUsed;
    }

    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);
    event ModifiedEscrowAddress(uint256 newEscrowAddress);
    event ModifiedEscrowClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);
    event ModifiedEscrowClaimPaymentBatchSelector(uint256 newEscrowClaimPaymentSelector);

    mapping(bytes32 => TransferInfo) public transfers;
    address private _marketMaker;
    IStarknetMessaging private _snMessaging;
    uint256 private _snEscrowAddress;
    uint256 private _snEscrowClaimPaymentSelector;
    uint256 private _snEscrowClaimPaymentBatchSelector;

    constructor() {
        _disableInitializers();
    }

    // no constructors can be used in upgradeable contracts. 
    function initialize(
        address snMessaging,
        uint256 snEscrowAddress,
        uint256 snEscrowClaimPaymentSelector,
        uint256 snEscrowClaimPaymentBatchSelector,
        address marketMaker) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _snEscrowAddress = snEscrowAddress;
        _snEscrowClaimPaymentSelector = snEscrowClaimPaymentSelector;
        _snEscrowClaimPaymentBatchSelector = snEscrowClaimPaymentBatchSelector;
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

    function claimPayment(uint256 orderId, uint256 destAddress, uint256 amount) external payable onlyOwnerOrMM {
        _claimPayment(orderId, destAddress, amount);

        uint256[] memory payload = new uint256[](5);
        payload[0] = uint128(orderId); // low
        payload[1] = uint128(orderId >> 128); // high
        payload[2] = destAddress;
        payload[3] = uint128(amount); // low
        payload[4] = uint128(amount >> 128); // high
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowClaimPaymentSelector,
            payload);
    }

    function claimPaymentBatch(
        uint256[] calldata orderIds,
        uint256[] calldata destAddresses, 
        uint256[] calldata amounts
    ) external payable onlyOwnerOrMM() {
        require(orderIds.length == destAddresses.length, "Invalid lengths.");
        require(orderIds.length == amounts.length, "Invalid lengths.");

        uint256[] memory payload = new uint256[](5 * orderIds.length + 1);

        payload[0] = orderIds.length;
        
        for (uint32 idx = 0; idx < orderIds.length; idx++) {
            uint256 orderId = orderIds[idx];
            uint256 destAddress = destAddresses[idx];
            uint256 amount = amounts[idx];

            _claimPayment(orderId, destAddress, amount);

            uint32 base_idx = 1 + 5 * idx;
            payload[base_idx] = uint128(orderId); // low
            payload[base_idx + 1] = uint128(orderId >> 128); // high
            payload[base_idx + 2] = destAddress;
            payload[base_idx + 3] = uint128(amount); // low
            payload[base_idx + 4] = uint128(amount >> 128); // high
        }
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            _snEscrowAddress,
            _snEscrowClaimPaymentBatchSelector,
            payload);
    }

    function _claimPayment(uint256 orderId, uint256 destAddress, uint256 amount) internal view {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");
    }

    function setEscrowAddress(uint256 snEscrowAddress) external onlyOwner {
        _snEscrowAddress = snEscrowAddress;
        emit ModifiedEscrowAddress(snEscrowAddress);        
    }

    function setEscrowClaimPaymentSelector(uint256 snEscrowClaimPaymentSelector) external onlyOwner {
        _snEscrowClaimPaymentSelector = snEscrowClaimPaymentSelector;
        emit ModifiedEscrowClaimPaymentSelector(snEscrowClaimPaymentSelector);
    }

    function setEscrowClaimPaymentBatchSelector(uint256 snEscrowClaimPaymentBatchSelector) external onlyOwner {
        _snEscrowClaimPaymentBatchSelector = snEscrowClaimPaymentBatchSelector;
        emit ModifiedEscrowClaimPaymentBatchSelector(snEscrowClaimPaymentBatchSelector);
    }

    function getEscrowAddress() external view returns (uint256) {
        return _snEscrowAddress;
    }

    function getEscrowClaimPaymentSelector() external view returns (uint256) {
        return _snEscrowClaimPaymentSelector;
    }

    function getEscrowClaimPaymentBatchSelector() external view returns (uint256) {
        return _snEscrowClaimPaymentBatchSelector;
    }
    
    
    //// MM ACL:

    function getMMAddress() external view returns (address) {
        return _marketMaker;
    }

    function setMMAddress(address newMMAddress) external onlyOwner {
        _marketMaker = newMMAddress;
    }

    modifier onlyOwnerOrMM {
        require(msg.sender == owner() || msg.sender == _marketMaker, "Only Owner or MM can call this function");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
