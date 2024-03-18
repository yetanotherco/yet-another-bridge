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

    event ModifiedZKSyncEscrowAddress(address newEscrowAddress);
    event ModifiedStarknetEscrowAddress(uint256 newEscrowAddress);
    event ModifiedStarknetClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);

    //using the following uint8 AS A LIST OF 8 BITS:
    //first (rightmost) bit: isTransferred, second bit: isClaimed. next 6 bits are currently unused
    mapping(bytes32 => uint8) public transfers; 
    address public marketMaker;
    uint256 public StarknetEscrowAddress;
    address public ZKSyncEscrowAddress;
    uint256 public StarknetEscrowClaimPaymentSelector;
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
        address marketMaker_,
        address ZKSyncDiamondProxyAddress) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _ZKSyncDiamondProxy = IZkSync(ZKSyncDiamondProxyAddress);

        StarknetEscrowAddress = StarknetEscrowAddress_;
        StarknetEscrowClaimPaymentSelector = StarknetEscrowClaimPaymentSelector_; // TODO remove this or set the correct value in init
        marketMaker = marketMaker_;
    }

    //TODO compare gas costs of passing the index or the value
    function hasTransferred(bytes32 index) private view returns (bool) {
        return (transfers[index] & 1) == 1;
    }

    function hasClaimed(bytes32 index) private view returns (bool) {
        return ((transfers[index] >> 1) & 1) == 1;
    }

//TODO: change orderID to uint32
    function transfer(uint256 orderId, address destAddress, Chain chainId) external payable onlyOwnerOrMM {
        require(msg.value > 0, "Invalid amount, should be higher than 0.");

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, msg.value, chainId));

        require(hasTransferred(index) == false, "Transfer already processed.");
        transfers[index] = 1; //now this transfer is in progress

        (bool success,) = payable(destAddress).call{value: msg.value}(""); //34000 gas

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, destAddress, msg.value, chainId); //3000 gas (todo verify gas)
    }

    function claimPayment(uint256 orderId, address destAddress, uint256 amount) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, Chain.Starknet));
        require(hasTransferred(index) == true, "Transfer not found.");
        require(hasClaimed(index) == false, "Transfer already claimed.");
        transfers[index] = 3; //now this transfer is claimed

        uint256[] memory payload = new uint256[](3);
        payload[0] = uint256(orderId);
        payload[1] = uint256(uint160(destAddress));
        payload[2] = uint256(amount);
        
        _snMessaging.sendMessageToL2{value: msg.value}(
            StarknetEscrowAddress,
            StarknetEscrowClaimPaymentSelector,
            payload);
    }

    function claimPaymentZKSync(
        uint256 orderId, address destAddress, uint256 amount,
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit
    ) external payable onlyOwnerOrMM {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, Chain.ZKSync));
        require(hasTransferred(index) == true, "Transfer not found.");
        require(hasClaimed(index) == false, "Transfer already claimed.");
        transfers[index] = 3; //now this transfer is claimed

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
