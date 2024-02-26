//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


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
    struct SetOrder {
        uint256 order_id;
        address recipient_address;
        uint256 amount;
        uint256 fee;
    }
    struct ClaimPayment {
        uint256 order_id;
        address claimerAddress;
        uint256 amount;
    }

    // enum Event {
    //     ClaimPayment: ClaimPayment,
    //     SetOrder: SetOrder,
    //     #[flat]
    //     OwnableEvent: OwnableComponent::Event,
    //     #[flat]
    //     UpgradeableEvent: UpgradeableComponent::Event,
    //     #[flat]
    //     PausableEvent: PausableComponent::Event
    // }

    //storage
    uint256 private _current_order_id; 
    mapping(uint256 => Order) private _orders;
    mapping(uint256 => bool) private _orders_pending;
    mapping(uint256 => address) private _orders_senders;
    mapping(uint256 => uint64) private _orders_timestamps;
    address public ethereum_payment_registry; //called eth_transfer_contract in cairo
    address public mm_ethereum_wallet;
    address public mm_zksync_wallet; //verify this is address type
    address public native_token_eth_in_zksync; //erc20 of eth in zksync

    function initialize(
        address ethereum_payment_registry_,
        address mm_ethereum_wallet_,
        address mm_zksync_wallet_,
        address native_token_eth_in_zksync_
    ) public initializer {
        __Ownable_init();
        // __UUPSUpgradeable_init();
        _transferOwnership(0xB321099cf86D9BB913b891441B014c03a6CcFc54);

        _current_order_id = 0;
        ethereum_payment_registry = ethereum_payment_registry_;
        mm_ethereum_wallet = mm_ethereum_wallet_;
        mm_zksync_wallet = mm_zksync_wallet_;
        native_token_eth_in_zksync = native_token_eth_in_zksync_;
    }


    //functions
    function helloworld() public view returns (uint256) {
        return _current_order_id;
    }

    function setC(uint256 newNumber) public {
        _current_order_id = newNumber;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}
