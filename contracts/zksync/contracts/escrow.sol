//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// TODO make upgradeable

contract Escrow is Initializable, OwnableUpgradeable, PausableUpgradeable { //}, UUPSUpgradeable {

    using SafeERC20 for IERC20;

    struct Order {
        address recipient_address;
        uint256 amount;
        uint256 fee;
    }

    struct OrderERC20 {
        address recipient_address;
        uint256 amount;
        uint256 fee;
        address l1_erc20_address;
        address l2_erc20_address;
    }

    event SetOrder(uint256 order_id, address recipient_address, uint256 amount, uint256 fee);
    event SetOrderERC20(uint256 order_id, address recipient_address, uint256 amount, uint256 fee, address l1_erc20_address, address l2_erc20_address);
    
    event ClaimPayment(uint256 order_id, address claimer_address, uint256 amount);
    event ClaimPaymentERC20(uint256 order_id, address claimer_address, uint256 amount, address l2_erc20_address);


    //storage
    uint256 private _current_order_id; 
    mapping(uint256 => Order) private _orders;
    mapping(uint256 => OrderERC20) private _orders_erc20;
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

        ethereum_payment_registry = ethereum_payment_registry_;
        mm_zksync_wallet = mm_zksync_wallet_;
    }


    // FUNCTIONS :

    //I think this is not OK. here, the caller of safeIncreaseAllowance isPaymentRegistry
    function increase_erc20_allowance(address l2_erc20_address, uint256 amount) public whenNotPaused {
        IERC20(l2_erc20_address).safeIncreaseAllowance(msg.sender, amount); //do allow max amount? same price to execute and saves a posterior need of execution
    }

    //Function recieves in msg.value the total fee for MM, and in amout the total tokens he wants to bridge
    function set_order_erc20(address recipient_address, uint256 amount, address l1_erc20_address, address l2_erc20_address) public payable whenNotPaused returns (uint256) {
        require(msg.value > 0, 'some ETH must be sent as MM fees');
        require(amount > 0, 'some tokens must be sent to bridge');
        
        //the following needs allowance, which is not set automatically
        require(IERC20(l2_erc20_address).balanceOf(msg.sender) >= amount, "User has insuficient funds");
        require(IERC20(l2_erc20_address).allowance(msg.sender, address(this)) >= amount, "Escrow has insuficient allowance");
        IERC20(l2_erc20_address).safeTransferFrom(msg.sender, address(this), amount); //will revert if failed

        OrderERC20 memory new_order = OrderERC20({recipient_address: recipient_address, amount: amount, fee: msg.value, l1_erc20_address: l1_erc20_address, l2_erc20_address: l2_erc20_address});
        _orders_erc20[_current_order_id] = new_order;
        _orders_pending[_current_order_id] = true;
        _orders_senders[_current_order_id] = msg.sender;
        _orders_timestamps[_current_order_id] = block.timestamp;
        _current_order_id++; //this here to follow CEI pattern

        emit SetOrderERC20(_current_order_id-1, recipient_address, amount, msg.value, l1_erc20_address, l2_erc20_address);

        return _current_order_id-1;
    }

    // l1 handler
    function claim_payment_erc20(
        uint256 order_id,
        address recipient_address,
        uint256 amount,
        address l1_erc20_address
    ) public whenNotPaused {
        require(msg.sender == ethereum_payment_registry, 'Only PAYMENT_REGISTRY can call');
        require(_orders_pending[order_id], 'Order claimed or nonexistent');

        OrderERC20 memory current_order = _orders_erc20[order_id]; //TODO check if order is memory or calldata
        require(current_order.recipient_address == recipient_address, 'recipient_address not match L1');
        require(current_order.amount == amount, 'amount not match L1');
        require(current_order.l1_erc20_address == l1_erc20_address, 'l1_erc20_address does not match L1');

        _orders_pending[order_id] = false;

        //transfer amount + fee in ETH:
        IERC20(current_order.l2_erc20_address).safeTransfer(mm_zksync_wallet, amount); //will revert if failed
        (bool success,) = payable(address(uint160(mm_zksync_wallet))).call{value: current_order.fee}("");
        require(success, "Fee transfer failed.");

        emit ClaimPaymentERC20(order_id, mm_zksync_wallet, amount, current_order.l2_erc20_address);
    }

    function get_order(uint256 order_id) public view returns (Order memory) {
        return _orders[order_id];
    }

    function get_order_erc20(uint256 order_id) public view returns (OrderERC20 memory) {
        return _orders_erc20[order_id];
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

    // l1 handler
    function claim_payment_batch(
        uint256[] calldata order_ids,
        address[] calldata recipient_addresses,
        uint256[] calldata amounts
    ) public whenNotPaused {
        require(msg.sender == ethereum_payment_registry, 'Only PAYMENT_REGISTRY can call');
        require(order_ids.length == recipient_addresses.length, 'Invalid lengths');
        require(order_ids.length == amounts.length, 'Invalid lengths');

        for (uint32 idx = 0; idx < order_ids.length; idx++) {
            uint256 order_id = order_ids[idx];
            address recipient_address = recipient_addresses[idx];
            uint256 amount = amounts[idx];

            require(_orders_pending[order_id], 'Order claimed or nonexistent');

            Order memory current_order = _orders[order_id]; //TODO check if order is memory or calldata
            require(current_order.recipient_address == recipient_address, 'recipient_address not match L1');
            require(current_order.amount == amount, 'amount not match L1');

            _orders_pending[order_id] = false;
            uint256 payment_amount = current_order.amount + current_order.fee;  // TODO check overflow

            // TODO: Might be best to do only one transfer
            (bool success,) = payable(address(uint160(mm_zksync_wallet))).call{value: payment_amount}("");
            require(success, "Transfer failed.");

            emit ClaimPayment(order_id, mm_zksync_wallet, amount);
        }
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
