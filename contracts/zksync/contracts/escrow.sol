//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// TODO make upgradeable

contract Escrow is Initializable, OwnableUpgradeable, PausableUpgradeable { //}, UUPSUpgradeable {

    struct Order {
        address recipient_address;
        uint256 amount;
        uint256 fee;
    }

    event SetOrder(uint256 order_id, address recipient_address, uint256 amount, uint256 fee);
    
    event ClaimPayment(uint256 order_id, address claimerAddress, uint256 amount);

    //storage
    uint256 private _current_order_id; 
    mapping(uint256 => Order) private _orders;
    mapping(uint256 => bool) private _orders_pending;
    mapping(uint256 => address) private _orders_senders;
    mapping(uint256 => uint256) private _orders_timestamps;
    address public ethereum_payment_registry; //called eth_transfer_contract in cairo
    address public mm_ethereum_wallet;
    address public mm_zksync_wallet; //TODO verify this is address type, creo que si
    ERC20 public native_token_eth_in_zksync; //TODO make this value internal and hardcoded

    function initialize(
        address ethereum_payment_registry_,
        address mm_ethereum_wallet_,
        address mm_zksync_wallet_,
        address native_token_eth_in_zksync_
    ) public initializer {
        __Ownable_init();
        // __UUPSUpgradeable_init();

        _current_order_id = 0;
        ethereum_payment_registry = ethereum_payment_registry_;
        mm_ethereum_wallet = mm_ethereum_wallet_;
        mm_zksync_wallet = mm_zksync_wallet_;
        native_token_eth_in_zksync = ERC20(native_token_eth_in_zksync_);
    }


    // FUNCTIONS :

    function get_order(uint256 order_id) public view returns (Order memory) {
        return _orders[order_id];
    }

    function set_order(Order calldata new_order) public whenNotPaused returns (uint256) {
        require(new_order.amount > 0, 'Amount must be greater than 0');

        uint256 payment_amount = new_order.amount + new_order.fee; // TODO check overflow
        require(native_token_eth_in_zksync.allowance(msg.sender, address(this)) >= payment_amount, 'Not enough allowance');
        require(native_token_eth_in_zksync.balanceOf(msg.sender) >= payment_amount, 'Not enough allowance');
        
        _orders[_current_order_id] = new_order;
        _orders_pending[_current_order_id] = true;
        _orders_senders[_current_order_id] = msg.sender;
        _orders_timestamps[_current_order_id] = block.timestamp;
        _current_order_id++;

        native_token_eth_in_zksync.transferFrom(msg.sender, address(this), payment_amount);

        emit SetOrder(_current_order_id-1, new_order.recipient_address, new_order.amount, new_order.fee);

        return _current_order_id;
    }

    function get_order_pending(uint256 order_id) public view returns (bool) {
        return _orders_pending[order_id];
    }

    function set_ethereum_payment_registry(address new_payment_registry_address) public whenNotPaused onlyOwner {
        ethereum_payment_registry = new_payment_registry_address;
    }

    function set_mm_ethereum_wallet(address new_mm_eth_wallet) public whenNotPaused onlyOwner {
        mm_ethereum_wallet = new_mm_eth_wallet;
    }

    function set_mm_zksync_wallet(address new_mm_zksync_wallet) public whenNotPaused onlyOwner {
        mm_zksync_wallet = new_mm_zksync_wallet;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // l1 handler
    function claim_payment(
        uint256 order_id,
        address recipient_address,
        uint256 amount
    ) public whenNotPaused {
        require(msg.sender == ethereum_payment_registry, 'Only PAYMENT_REGISTRY_CONTRACT');
        require(_orders_pending[order_id], 'Order claimed or nonexistent');

        Order memory current_order = _orders[order_id]; //TODO check if order is memory
        require(current_order.recipient_address == recipient_address, 'recipient_address not match L1');
        require(current_order.amount == amount, 'amount not match L1');

        _orders_pending[order_id] = false;
        uint256 payment_amount = current_order.amount + current_order.fee;  // TODO check overflow

        native_token_eth_in_zksync.transfer(mm_zksync_wallet, payment_amount);

        emit ClaimPayment(order_id, mm_zksync_wallet, amount);
    }

    // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}
