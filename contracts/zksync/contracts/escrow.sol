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
    address public ethereum_payment_registry;
    address public mm_zksync_wallet;

    function initialize(
        address ethereum_payment_registry_,
        address mm_zksync_wallet_
    ) public initializer {
        __Ownable_init();
        // __UUPSUpgradeable_init();

        _current_order_id = 0;
        ethereum_payment_registry = ethereum_payment_registry_;
        mm_zksync_wallet = mm_zksync_wallet_;
    }


    // FUNCTIONS :

    function get_order(uint256 order_id) public view returns (Order memory) {
        return _orders[order_id];
    }

    //Function recieves in msg.value the total value, and in fee the user specifies what portion of that msg.value is fee for MM
    function set_order(address recipient_address, uint256 fee) public payable whenNotPaused returns (uint256) {
        require(msg.value > 0, 'some ETH must be sent');
        require(msg.value > fee, 'ETH sent must be more than fee');

        uint256 bridge_amount = msg.value - fee; //no underflow since previous check is made
        
        Order memory new_order = Order({recipient_address: recipient_address, amount: bridge_amount, fee: fee});
        _orders[_current_order_id] = new_order;
        _orders_pending[_current_order_id] = true;
        _orders_senders[_current_order_id] = msg.sender;
        _orders_timestamps[_current_order_id] = block.timestamp;
        _current_order_id++; //this here to follow CEI pattern

        emit SetOrder(_current_order_id-1, recipient_address, bridge_amount, fee);

        return _current_order_id-1;
    }

    // l1 handler
    function claim_payment(
        uint256 order_id,
        address recipient_address,
        uint256 amount
    ) public whenNotPaused {
        require(msg.sender == ethereum_payment_registry, 'Only PAYMENT_REGISTRY can call');
        require(_orders_pending[order_id], 'Order claimed or nonexistent');

        Order memory current_order = _orders[order_id]; //TODO check if order is memory or calldata
        require(current_order.recipient_address == recipient_address, 'recipient_address not match L1');
        require(current_order.amount == amount, 'amount not match L1');

        _orders_pending[order_id] = false;
        uint256 payment_amount = current_order.amount + current_order.fee;  // TODO check overflow

        (bool success,) = payable(address(uint160(mm_zksync_wallet))).call{value: payment_amount}("");
        require(success, "Transfer failed.");

        emit ClaimPayment(order_id, mm_zksync_wallet, amount);
    }

    function is_order_pending(uint256 order_id) public view returns (bool) {
        return _orders_pending[order_id];
    }

    function set_ethereum_payment_registry(address new_payment_registry_address) public whenNotPaused onlyOwner {
        ethereum_payment_registry = new_payment_registry_address;
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

    //todo for upgradeable in zksync:
    // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}
