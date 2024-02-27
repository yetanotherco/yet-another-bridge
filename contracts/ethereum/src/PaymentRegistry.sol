// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PaymentRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    enum Chain { Starknet, ZKSync }

    struct TransferInfo {
        uint256 destAddress;
        uint256 amount;
        bool isUsed;
        Chain chainID;
    }

    event Transfer(uint256 indexed orderId, address srcAddress, TransferInfo transferInfo);
    event ModifiedZKSyncEscrowAddress(uint256 newEscrowAddress);
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


    function transfer(uint256 orderId, uint256 destAddress, uint256 amount, Chain chainID) external payable onlyOwnerOrMM {
        require(destAddress != 0, "Invalid destination address.");
        require(amount > 0, "Invalid amount, should be higher than 0.");
        require(msg.value == amount, "Invalid amount, should match msg.value.");

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        require(transfers[index].isUsed == false, "Transfer already processed.");

        transfers[index] = TransferInfo({destAddress: destAddress, amount: amount, isUsed: true, chainID: chainID});

        (bool success,) = payable(address(uint160(destAddress))).call{value: msg.value}("");

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, transfers[index]);
    }

    function claimPayment(uint256 orderId, uint256 destAddress, uint256 amount, Chain chainID) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount));
        TransferInfo storage transferInfo = transfers[index];
        require(transferInfo.isUsed == true, "Transfer not found.");
        require(transferInfo.chainID == chainID, "Wrong ChainID");

        if(chainID == Chain.Starknet) {
            
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
                
        } else if(chainID == Chain.ZKSync) {

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

        } else {
            require(false, "Unsupported ChainID");
        }
    }

    function claimPaymentZKSync(
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit
    ) external payable {
        require(msg.sender == governor, "Only governor is allowed");

        bytes data = wip;

        _ZKSyncCoreContract.requestL2Transaction{value: msg.value}(ZKSyncEscrowAddress, 0, 
            data, gasLimit, gasPerPubdataByteLimit, new bytes[](0), msg.sender);

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
