// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IStarknetMessaging} from "starknet/IStarknetMessaging.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IZkSync} from "@matterlabs/interfaces/IZkSync.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
 

contract PaymentRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    using SafeERC20 for IERC20;

    event Transfer(uint256 indexed orderId, address srcAddress, address destAddress, uint256 amount, uint128 chainId);
    event TransferERC20(uint256 indexed orderId, address srcAddress, address destAddress, uint256 amount, uint128 chainId, address erc20Address);

    event ClaimPayment(uint256 indexed orderId, address destAddress, uint256 amount, uint128 chainId);
    event ClaimPaymentERC20(uint256 indexed orderId, address destAddress, uint256 amount, uint128 chainId, address erc20Address);
    event ClaimPaymentBatch(uint256[] orderIds, address[] destAddresses, uint256[] amounts, uint128 chainId);

    event ModifiedZKSyncEscrowAddress(address newEscrowAddress);
    event ModifiedStarknetEscrowAddress(uint256 newEscrowAddress);
    
    event ModifiedStarknetClaimPaymentSelector(uint256 newEscrowClaimPaymentSelector);
    event ModifiedStarknetClaimPaymentBatchSelector(uint256 newEscrowClaimPaymentBatchSelector);
    event ModifiedStarknetClaimPaymentERC20Selector(uint256 newEscrowClaimPaymentERC20Selector);

    event ModifiedZKSyncClaimPaymentSelector(bytes4 newZKSyncEscrowClaimPaymentSelector);
    event ModifiedZKSyncClaimPaymentBatchSelector(bytes4 newZKSyncEscrowClaimPaymentBatchSelector);
    event ModifiedZKSyncClaimPaymentERC20Selector(bytes4 newZKSyncEscrowClaimPaymentERC20Selector);

    mapping(bytes32 => bool) public transfers;
    address public marketMaker;
    uint256 public StarknetEscrowAddress;
    address public ZKSyncEscrowAddress;
    uint256 public StarknetEscrowClaimPaymentSelector;
    uint256 public StarknetEscrowClaimPaymentBatchSelector;
    uint256 public StarknetEscrowClaimPaymentERC20Selector;
    bytes4 public ZKSyncEscrowClaimPaymentSelector;
    bytes4 public ZKSyncEscrowClaimPaymentBatchSelector;
    bytes4 public ZKSyncEscrowClaimPaymentERC20Selector;

    IZkSync private _ZKSyncDiamondProxy;
    IStarknetMessaging private _snMessaging;

    //According to EIP-155, ChainIds are uint32, but as Starknet decided to not follow this EIP, we must store them as uint128.
    uint128 public StarknetChainId;
    uint128 public ZKSyncChainId;

    constructor() {
        _disableInitializers();
    }

    // no constructors can be used in upgradeable contracts. 
    function initialize(
        address snMessaging,
        uint256 StarknetEscrowClaimPaymentSelector_,
        uint256 StarknetEscrowClaimPaymentBatchSelector_,
        uint256 StarknetEscrowClaimPaymentERC20Selector_,
        address marketMaker_,
        address ZKSyncDiamondProxyAddress,
        bytes4 ZKSyncEscrowClaimPaymentSelector_,
        bytes4 ZKSyncEscrowClaimPaymentBatchSelector_,
        bytes4 ZKSyncEscrowClaimPaymentERC20Selector_,
        uint128 StarknetChainId_,
        uint128 ZKSyncChainId_) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _snMessaging = IStarknetMessaging(snMessaging);
        _ZKSyncDiamondProxy = IZkSync(ZKSyncDiamondProxyAddress);

        StarknetEscrowClaimPaymentSelector = StarknetEscrowClaimPaymentSelector_;
        StarknetEscrowClaimPaymentBatchSelector = StarknetEscrowClaimPaymentBatchSelector_;
        StarknetEscrowClaimPaymentERC20Selector = StarknetEscrowClaimPaymentERC20Selector_;
        ZKSyncEscrowClaimPaymentSelector = ZKSyncEscrowClaimPaymentSelector_;
        ZKSyncEscrowClaimPaymentBatchSelector = ZKSyncEscrowClaimPaymentBatchSelector_;
        ZKSyncEscrowClaimPaymentERC20Selector = ZKSyncEscrowClaimPaymentERC20Selector_;

        StarknetChainId = StarknetChainId_;
        ZKSyncChainId = ZKSyncChainId_;

        marketMaker = marketMaker_;
    }
    
    function transferERC20(uint256 orderId, address destAddress, uint128 chainId, address l1_erc20_address, uint256 amount) external onlyOwnerOrMM {
        // Decide if MM fees are paid in ERC20 or in ETH.
        // // If paid in ETH:
        // // It is easy for MM to calculate how much fee is desirable for him to bridge the tokens
        // // But An extra tx is needed containing this gas.
        // // it is more expensive

        // // If paid in ERC20:
        // // MM can get paid in a random coin, price may vary, more difficult for MM to determine how much ERC20 tokens are necesarry.
        // // But MM only subscribes to desired ERC20. For example if he only bridges USDT, he may be willing to take USDT as fee for bridge.
        // // No extra tx is needed to pay this gas fee, MM will simply transfer less ERC20 tokens than what he recieved.
        // // It is cheaper

        // // Allowance:
        // // This unlimited allowance should be set in a separate function. MM will allow to brdige x or y ERC20.
        // // // we could even find new uses for this allowance. PaymentRegistry could be more intertwined with MM. Maybe automatically doing transfers in its name.
        
        require(amount > 0, "Invalid amount, should be higher than 0.");

        // these 2 checks are made and reverted accordingly by SafeTransfer
        // but if made now, if reverted, user doesnt spend the gas of calculating keccak
        // I think appropriate users should not pay for shitty users's mustakes
        // require(IERC20(l1_erc20_address).balanceOf(msg.sender) >= amount, "MM has insufficient balance");
        // require(IERC20(l1_erc20_address).allowance(msg.sender, address(this)) >= amount, "PaymentRegistry has insufficient allowance");
        //TODO check if there is a way to increment allowance directly from here, i think there is not.

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, chainId, l1_erc20_address)); //added erc20Address

        require(transfers[index] == false, "Transfer already processed.");
        transfers[index] = true; //now this transfer is in progress

        IERC20(l1_erc20_address).safeTransferFrom(msg.sender, destAddress, amount); //this reverts if failed
        emit TransferERC20(orderId, msg.sender, destAddress, amount, chainId, l1_erc20_address);
    }

    function claimPaymentZKSyncERC20(
        uint256 orderId,
        address destAddress,
        uint256 amount,
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit,
        address l1_erc20_address
    ) external payable onlyOwnerOrMM {
        _verifyTransferExistsZKSyncERC20(orderId, destAddress, amount, l1_erc20_address);

        bytes memory messageToL2 = abi.encodeWithSelector(
            ZKSyncEscrowClaimPaymentERC20Selector,
            orderId,
            destAddress,    
            amount,
            l1_erc20_address
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

        emit ClaimPaymentERC20(orderId, destAddress, amount, ZKSyncChainId, l1_erc20_address);
    }

    function claimPaymentStarknetERC20(
        uint256 orderId,
        address destAddress,
        uint256 amount,
        address l1_erc20_address
    ) external payable onlyOwnerOrMM {
        _verifyTransferExistsStarknetERC20(orderId, destAddress, amount, l1_erc20_address);

        uint256[] memory payload = new uint256[](6); //this is not an array of u128 because sendMessageToL2 takes an array of uint256
        payload[0] = uint128(orderId); // low
        payload[1] = uint128(orderId >> 128); // high
        payload[2] = uint256(uint160(destAddress));
        payload[3] = uint128(amount); // low
        payload[4] = uint128(amount >> 128); // high
        payload[5] = uint256(uint160(l1_erc20_address));

        _snMessaging.sendMessageToL2{value: msg.value}(
            StarknetEscrowAddress,
            StarknetEscrowClaimPaymentERC20Selector, //TODO set erc20 variable
            payload);

        emit ClaimPaymentERC20(orderId, destAddress, amount, StarknetChainId, l1_erc20_address);
    }

    function transfer(uint256 orderId, address destAddress, uint128 chainId) external payable onlyOwnerOrMM {
        require(msg.value > 0, "Invalid amount, should be higher than 0.");

        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, msg.value, chainId));

        require(transfers[index] == false, "Transfer already processed.");
        transfers[index] = true; //now this transfer is in progress

        (bool success,) = payable(destAddress).call{value: msg.value}(""); //34000 gas

        require(success, "Transfer failed.");
        emit Transfer(orderId, msg.sender, destAddress, msg.value, chainId); //2400 gas
    }

    function claimPaymentStarknet(uint256 orderId, address destAddress, uint256 amount) external payable onlyOwnerOrMM {
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

        emit ClaimPayment(orderId, destAddress, amount, StarknetChainId);
    }

    function claimPaymentBatchStarknet(
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

        emit ClaimPaymentBatch(orderIds, destAddresses, amounts, StarknetChainId);
    }

    function claimPaymentZKSync(
        uint256 orderId, address destAddress, uint256 amount,
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit
    ) external payable onlyOwnerOrMM {
        _verifyTransferExistsZKSync(orderId, destAddress, amount);

        bytes memory messageToL2 = abi.encodeWithSelector(
            ZKSyncEscrowClaimPaymentSelector,
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

        emit ClaimPayment(orderId, destAddress, amount, ZKSyncChainId); //2100 gas
    }

    function claimPaymentBatchZKSync(
        uint256[] calldata orderIds,
        address[] calldata destAddresses, 
        uint256[] calldata amounts,
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit
    ) external payable onlyOwnerOrMM {
        require(orderIds.length == destAddresses.length, "Invalid lengths.");
        require(orderIds.length == amounts.length, "Invalid lengths.");

        for (uint32 idx = 0; idx < orderIds.length; idx++) {
            _verifyTransferExistsZKSync(orderIds[idx], destAddresses[idx], amounts[idx]);
        }

        bytes memory messageToL2 = abi.encodeWithSelector(
            ZKSyncEscrowClaimPaymentBatchSelector,
            orderIds,
            destAddresses,
            amounts
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

        emit ClaimPaymentBatch(orderIds, destAddresses, amounts, ZKSyncChainId);
    }

    function _verifyTransferExistsStarknetERC20(uint256 orderId, address destAddress, uint256 amount, address l1_erc20_address) internal view {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, StarknetChainId, l1_erc20_address));
        require(transfers[index] == true, "Transfer not found."); //if this is claimed twice, Escrow will know
    }

    function _verifyTransferExistsStarknet(uint256 orderId, address destAddress, uint256 amount) internal view {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, StarknetChainId));
        require(transfers[index] == true, "Transfer not found."); //if this is claimed twice, Escrow will know
    }

    function _verifyTransferExistsZKSyncERC20(uint256 orderId, address destAddress, uint256 amount, address l1_erc20_address) internal view {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, ZKSyncChainId, l1_erc20_address));
        require(transfers[index] == true, "Transfer not found."); //if this is claimed twice, Escrow will know
    }

    function _verifyTransferExistsZKSync(uint256 orderId, address destAddress, uint256 amount) internal view {
        bytes32 index = keccak256(abi.encodePacked(orderId, destAddress, amount, ZKSyncChainId));
        require(transfers[index] == true, "Transfer not found."); //if this is claimed twice, Escrow will know
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

    function setStarknetClaimPaymentBatchSelector(uint256 NewStarknetEscrowClaimPaymentBatchSelector) external onlyOwner {
        StarknetEscrowClaimPaymentBatchSelector = NewStarknetEscrowClaimPaymentBatchSelector;
        emit ModifiedStarknetClaimPaymentBatchSelector(StarknetEscrowClaimPaymentBatchSelector);
    }

    function setStarknetClaimPaymentERC20Selector(uint256 NewStarknetEscrowClaimPaymentERC20Selector) external onlyOwner {
        StarknetEscrowClaimPaymentERC20Selector = NewStarknetEscrowClaimPaymentERC20Selector;
        emit ModifiedStarknetClaimPaymentERC20Selector(StarknetEscrowClaimPaymentERC20Selector);
    }

    function setZKSyncEscrowClaimPaymentSelector(bytes4 NewZKSyncEscrowClaimPaymentSelector) external onlyOwner {
        ZKSyncEscrowClaimPaymentSelector = NewZKSyncEscrowClaimPaymentSelector;
        emit ModifiedZKSyncClaimPaymentSelector(ZKSyncEscrowClaimPaymentSelector);
    }

    function setZKSyncEscrowClaimPaymentBatchSelector(bytes4 NewZKSyncEscrowClaimPaymentBatchSelector) external onlyOwner {
        ZKSyncEscrowClaimPaymentBatchSelector = NewZKSyncEscrowClaimPaymentBatchSelector;
        emit ModifiedZKSyncClaimPaymentBatchSelector(ZKSyncEscrowClaimPaymentBatchSelector);
    }

    function setZKSyncEscrowClaimPaymentERC20Selector(bytes4 NewZKSyncEscrowClaimPaymentERC20Selector) external onlyOwner {
        ZKSyncEscrowClaimPaymentERC20Selector = NewZKSyncEscrowClaimPaymentERC20Selector;
        emit ModifiedZKSyncClaimPaymentERC20Selector(ZKSyncEscrowClaimPaymentERC20Selector);
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
