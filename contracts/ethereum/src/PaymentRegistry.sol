// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IZkSync} from "@matterlabs/interfaces/IZkSync.sol";

contract PaymentRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    enum Chain { Starknet, ZKSync }

    struct TransferInfo {
        uint256 destAddress; //TODO consider changing to address type
        uint256 amount; //TODO consider lowering this data type
        bool isUsed;
        Chain chainId;
    }

    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);
    event ModifiedZKSyncEscrowAddress(address newEscrowAddress);
    event ModifiedStarknetEscrowAddress(uint256 newEscrowAddress);
    event ModifiedStarknetClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);

    mapping(bytes32 => TransferInfo) public transfers;
    address public marketMaker;
    uint256 public StarknetEscrowAddress;
    address public ZKSyncEscrowAddress;
    uint256 public StarknetEscrowClaimPaymentSelector;
    IZkSync private _ZKSyncCoreContract;
    IStarknetMessaging private _snMessaging;

    constructor() {
        _disableInitializers();
    }

    // no constructors can be used in upgradeable contracts. 
    function initialize(
        address snMessaging,
        uint256 StarknetEscrowAddress_,
        uint256 StarknetEscrowClaimPaymentSelector_,
        address marketMaker_,
        address ZKSyncCoreContractAddress) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _ZKSyncCoreContract = IZkSync(ZKSyncCoreContractAddress);

        StarknetEscrowAddress = StarknetEscrowAddress_;
        StarknetEscrowClaimPaymentSelector = StarknetEscrowClaimPaymentSelector_; // TODO remove this or set the correct value
        marketMaker = marketMaker_;
    }

//TODO: change orderID to uint32
    function transfer(uint256 orderId, uint256 destAddress, uint256 amount, Chain chainId) external payable onlyOwnerOrMM {
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value == amount, "Invalid amount, should match msg.value.");

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, chainId));
        require(transfers[index].isUsed == false, "Transfer already processed.");

        transfers[index] = TransferInfo({destAddress: destAddress, amount: amount, isUsed: true, chainId: chainId});

        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value}("");

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, transfers[index]);
    }

//TODO change name to claimPaymentStarknet
    function claimPayment(uint256 orderId, uint256 destAddress, uint256 amount) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, Chain.Starknet));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");

        uint256[] memory payload = new uint256[](5); //TODO why array of 256 if then filled with 128?
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

    function claimPaymentZKSync(
        uint256 orderId, uint256 destAddress, uint256 amount,
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit
    ) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, Chain.ZKSync));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");

            // IZkSync zksync = IZkSync(zkSyncAddress);
            // zksync.requestL2Transaction{value: msg.value}(
            //     ZKSyncEscrowAddress,    //address _contractL2,
            //     0,                      //uint256 _l2Value,
            //     payload,                //bytes calldata _calldata,
            //     msg.value,              //uint256 _l2GasLimit,
            //     REQUIRED_L1_TO_L2_GAS_PER_PUBDATA_LIMIT, //uint256 _l2GasPerPubdataByteLimit,
            //     new bytes[](0),         //bytes[] calldata _factoryDeps,
            //     msg.sender              //address _refundRecipient
            // );
            
            // L1 handler in escrow:
                // function claim_payment(
                //     uint256 order_id,
                //     address recipient_address,
                //     uint256 amount
                // )

        bytes memory payload = new bytes(32+32+32); //orderid, address(u256), amount, =96
        
        bytes32 p0 = bytes32(orderId);
        bytes32 p1 = bytes32(transferInfo.destAddress);
        bytes32 p2 = bytes32(amount);

        for(uint i=0; i < 32; i++){
            payload[64+i] = p0[i];  //write p0 in first 32 bytes
            payload[32+i] = p1[i];  //write p1 in middle 32 bytes
            payload[i] = p2[i];     //write p2 in last 32 bytes
        }

        _ZKSyncCoreContract.requestL2Transaction{value: msg.value}(ZKSyncEscrowAddress, 0, 
            payload, gasLimit, gasPerPubdataByteLimit, new bytes[](0), msg.sender);

    }

    function setStarknetEscrowAddress(uint256 newStarknetEscrowAddress) external onlyOwner {
        StarknetEscrowAddress = newStarknetEscrowAddress;
        emit ModifiedStarknetEscrowAddress(newStarknetEscrowAddress);        
    }

    function setZKSyncEscrowAddress(address newZKSyncEscrowAddress) external onlyOwner {
        ZKSyncEscrowAddress = newZKSyncEscrowAddress;
        emit ModifiedZKSyncEscrowAddress(newZKSyncEscrowAddress);        
    }

    function setStarknetClaimPaymentSelector(uint256 NewStarknetEscrowClaimPaymentSelector) external onlyOwner {
        StarknetEscrowClaimPaymentSelector = NewStarknetEscrowClaimPaymentSelector;
        emit ModifiedStarknetClaimPaymentSelector(StarknetEscrowClaimPaymentSelector);
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
