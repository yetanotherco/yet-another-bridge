// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IZkSync} from "@matterlabs/interfaces/IZkSync.sol";

contract PaymentRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    enum Chain { Starknet, ZKSync } //todo add canonic chainID

    event Transfer(uint256 indexed orderId, address srcAddress, address destAddress, uint256 amount, Chain chainId);
    event ClaimPayment(uint256 indexed orderId, address destAddress, uint256 amount, Chain chainId);

    event ModifiedZKSyncEscrowAddress(address newEscrowAddress);
    event ModifiedStarknetEscrowAddress(uint256 newEscrowAddress);
    event ModifiedStarknetClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);
    event ModifiedStarknetClaimPaymentBatchSelector(uint256 newEscrowClaimPaymentSelector);
    event ClaimPaymentBatch(uint256[] orderIds, address[] destAddresses, uint256[] amounts, Chain chainId);

    mapping(bytes32 => bool) public transfers;
    address public marketMaker;
    uint256 public StarknetEscrowAddress;
    address public ZKSyncEscrowAddress;
    uint256 public StarknetEscrowClaimPaymentSelector;
    uint256 public StarknetEscrowClaimPaymentBatchSelector;

    IZkSync private _ZKSyncDiamondProxy;
    IStarknetMessaging private _snMessaging;

    constructor() {
        _disableInitializers();
    }

    // no constructors can be used in upgradeable contracts. 
    function initialize(
        address snMessaging,
        uint256 StarknetEscrowAddress_,
        uint256 StarknetEscrowClaimPaymentSelector_,
        uint256 StarknetEscrowClaimPaymentBatchSelector_,
        address marketMaker_,
        address ZKSyncDiamondProxyAddress) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _ZKSyncDiamondProxy = IZkSync(ZKSyncDiamondProxyAddress);

        StarknetEscrowAddress = StarknetEscrowAddress_;
        StarknetEscrowClaimPaymentSelector = StarknetEscrowClaimPaymentSelector_; // TODO remove this or set the correct value in init
        StarknetEscrowClaimPaymentBatchSelector = StarknetEscrowClaimPaymentBatchSelector_; // TODO remove this or set the correct value in init

        marketMaker = marketMaker_;
    }

    //TODO: change orderID to uint32
    function transfer(uint256 orderId, address destAddress, Chain chainId) external payable onlyOwnerOrMM {
        require(msg.value > 0, "Invalid amount, should be higher than 0.");

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, msg.value, chainId));

        require(transfers[index] == false, "Transfer already processed.");
        transfers[index] = true; //now this transfer is in progress

        (bool success,) = payable(destAddress).call{value: msg.value}(""); //34000 gas

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, destAddress, msg.value, chainId); //2400 gas
    }

    function claimPayment(uint256 orderId, address destAddress, uint256 amount) external payable onlyOwnerOrMM {
        _verifyTransferExistsStarknet(orderId, destAddress, amount);

        uint256[] memory payload = new uint256[](5); //this is not an array of u128 because sendMessageToL2 takes an array of uint256
        payload[0] = uint128(orderId); // low
        payload[1] = uint128(orderId >> 128); // high
        payload[2] = uint256(uint160(destAddress));
        payload[3] = uint128(amount); // low
        payload[4] = uint128(amount >> 128); // high

        //10k gas:
        _snMessaging.sendMessageToL2{value: msg.value}(
            StarknetEscrowAddress,
            StarknetEscrowClaimPaymentSelector,
            payload);

        emit ClaimPayment(orderId, destAddress, amount, Chain.Starknet);
    }

    function claimPaymentBatch(
        uint256[] calldata orderIds,
        address[] calldata destAddresses,
        uint256[] calldata amounts
    ) external payable onlyOwnerOrMM() {
        require(orderIds.length == destAddresses.length, "Invalid lengths.");
        require(orderIds.length == amounts.length, "Invalid lengths.");

        uint256[] memory payload = new uint256[](5 * orderIds.length + 1);

        payload[0] = orderIds.length;

        for (uint32 idx = 0; idx < orderIds.length; idx++) {
            uint256 orderId = orderIds[idx];
            address destAddress = destAddresses[idx];
            uint256 amount = amounts[idx];

            _verifyTransferExistsStarknet(orderId, destAddress, amount);

            uint32 base_idx = 1 + 5 * idx;
            payload[base_idx] = uint128(orderId); // low
            payload[base_idx + 1] = uint128(orderId >> 128); // high
            payload[base_idx + 2] = uint256(uint160(destAddress));
            payload[base_idx + 3] = uint128(amount); // low
            payload[base_idx + 4] = uint128(amount >> 128); // high
        }

        _snMessaging.sendMessageToL2{value: msg.value}(
            StarknetEscrowAddress,
            StarknetEscrowClaimPaymentBatchSelector,
            payload);

        emit ClaimPaymentBatch(orderIds, destAddresses, amounts, Chain.Starknet);
    }

    function _verifyTransferExistsStarknet(uint256 orderId, address destAddress, uint256 amount) internal view {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, Chain.Starknet));
        require(transfers[index] == true, "Transfer not found.");
    }

    function claimPaymentZKSync(
        uint256 orderId, address destAddress, uint256 amount,
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit
    ) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, Chain.ZKSync));
        require(transfers[index] == true, "Transfer not found."); //if this is claimed twice, Escrow will know

        //todo change place of this var
        bytes4 selector = 0xa5168739; //claim_payment selector in ZKSync //todo add in init, same as in SN
        bytes memory messageToL2 = abi.encodeWithSelector(
            selector,
            orderId,
            destAddress,
            amount
        );

        _ZKSyncDiamondProxy.requestL2Transaction{value: msg.value}(
            ZKSyncEscrowAddress, //L2 contract called
            0, //msg.value
            messageToL2, //msg.calldata
            gasLimit, 
            gasPerPubdataByteLimit, 
            new bytes[](0), //factory dependencies
            msg.sender //refund recipient
        );

        emit ClaimPayment(orderId, destAddress, amount, Chain.ZKSync); //2100 gas
    }

    function setStarknetEscrowAddress(uint256 newStarknetEscrowAddress) external onlyOwner {
        StarknetEscrowAddress = newStarknetEscrowAddress;
        emit ModifiedStarknetEscrowAddress(newStarknetEscrowAddress);        
    }


    function setZKSyncEscrowAddress(address newZKSyncEscrowAddress) external onlyOwner {
        ZKSyncEscrowAddress = newZKSyncEscrowAddress;
        emit ModifiedZKSyncEscrowAddress(newZKSyncEscrowAddress);        
    }

    //todo change name to something more starknet-ish
    //this todo applies for this whole contract, but in a future change because MM-bot would need a refactor.
    function setStarknetClaimPaymentSelector(uint256 NewStarknetEscrowClaimPaymentSelector) external onlyOwner {
        StarknetEscrowClaimPaymentSelector = NewStarknetEscrowClaimPaymentSelector;
        emit ModifiedStarknetClaimPaymentSelector(StarknetEscrowClaimPaymentSelector);
    }

    function setStarknetClaimPaymentBatchSelector(uint256 NewStarknetEscrowClaimPaymentBatchSelector) external onlyOwner {
        StarknetEscrowClaimPaymentBatchSelector = NewStarknetEscrowClaimPaymentBatchSelector;
        emit ModifiedStarknetClaimPaymentBatchSelector(StarknetEscrowClaimPaymentBatchSelector);
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
