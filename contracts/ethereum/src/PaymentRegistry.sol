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
    event ModifiedZKSyncEscrowAddress(uint256 newEscrowAddress);
    event ModifiedStarknetEscrowAddress(uint256 newEscrowAddress);
    event ModifiedEscrowClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);

    mapping(bytes32 => TransferInfo) public transfers;
    address public marketMaker;
    uint256 public StarknetEscrowAddress;
    address public ZKSyncEscrowAddress;
    uint256 public StarknetEscrowClaimPaymentSelector;
    IStarknetMessaging private _snMessaging;

    constructor() {
        _disableInitializers();
    }

    // no constructors can be used in upgradeable contracts. 
    function initialize(
        address snMessaging,
        uint256 StarknetEscrowAddress_,
        uint256 StarknetEscrowClaimPaymentSelector_,
        address marketMaker_) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        StarknetEscrowAddress = StarknetEscrowAddress_;
        StarknetEscrowClaimPaymentSelector = StarknetEscrowClaimPaymentSelector_;
        marketMaker = marketMaker_;
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
            StarknetEscrowAddress,
            StarknetEscrowClaimPaymentSelector,
            payload);
    }

    //TODO make 1 claimPayment function, its less deployment price and better style
    function claimPaymentZK(uint256 orderId, address destAddress, uint256 amount, uint256 L2GasLimit) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");

        bytes[] memory payload = new bytes[](5); // TODO verify if this is the way eth calldatas are encoded
        payload[0] = uint128(orderId); // low
        payload[1] = uint128(orderId >> 128); // high
        payload[2] = transferInfo.destAddress;
        payload[3] = uint128(amount); // low
        payload[4] = uint128(amount >> 128); // high


        IZkSync zksync = IZkSync(zkSyncAddress);
        zksync.requestL2Transaction{value: msg.value}(ZKSyncEscrowAddress, 0,
            payload, L2GasLimit, REQUIRED_L1_TO_L2_GAS_PER_PUBDATA_LIMIT, new bytes[](0), msg.sender);

// function requestL2Transaction(
//     address _contractL2,
//     uint256 _l2Value,
//     bytes calldata _calldata,
//     uint256 _l2GasLimit,
//     uint256 _l2GasPerPubdataByteLimit,
//     bytes[] calldata _factoryDeps,
//     address _refundRecipient
// ) external payable returns (bytes32 canonicalTxHash);

    }

    function setStarknetEscrowAddress(uint256 newStarknetEscrowAddress) external onlyOwner {
        StarknetEscrowAddress = newStarknetEscrowAddress;
        emit ModifiedStarknetEscrowAddress(newStarknetEscrowAddress);        
    }

    function setZKSyncEscrowAddress(address newZKSyncEscrowAddress) external onlyOwner {
        ZKSyncEscrowAddress = newZKSyncEscrowAddress;
        emit ModifiedZKSyncEscrowAddress(newZKSyncEscrowAddress);        
    }

    function setEscrowClaimPaymentSelector(uint256 NewStarknetEscrowClaimPaymentSelector) external onlyOwner {
        StarknetEscrowClaimPaymentSelector = NewStarknetEscrowClaimPaymentSelector;
        emit ModifiedEscrowClaimPaymentSelector(StarknetEscrowClaimPaymentSelector);
    }
    
    
    //// MM ACL:

    function setMMAddress(address newMMAddress) external onlyOwner {
        marketMaker = newMMAddress;
    }

    modifier onlyOwnerOrMM {
        require(msg.sender == owner() || msg.sender == marketMaker, "Only Owner or MM can call this function");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
