//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract Escrow {//is Initializable, OwnableUpgradeable, UUPSUpgradeable{

    struct Order {
        address recipient_address;
        uint256 amount;
        uint256 fee;
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
    // #[derive(Drop, starknet::Event)]
    // struct SetOrder {
    //     order_id: u256,
    //     recipient_address: EthAddress,
    //     amount: u256,
    //     fee: u256
    // }
    // #[derive(Drop, starknet::Event)]
    // struct ClaimPayment {
    //     order_id: u256,
    //     address: ContractAddress,
    //     amount: u256,
    // }

    //storage
    uint256 private current_order_id; 
    mapping(uint256 => Order) private _orders;
    mapping(uint256 => bool) private orders_pending;
    mapping(uint256 => address) private orders_senders;
    mapping(uint256 => uint64) private orders_timestamps;
    address public ethereum_payment_registry; //called eth_transfer_contract in cairo
    address public mm_ethereum_wallet;
    address public mm_zksync_wallet; //verify this is address type
    address public native_token_eth_in_zksync; //erc20 of eth in zksync
    //ownable
    //upgradeable
    //pausable


    // no constructors can be used in upgradeable contracts. 
    constructor() {
        _disableInitializers(); //import from where?
    }

    function initialize(
        address ethereum_payment_registry_,
        address mm_ethereum_wallet_,
        address mm_zksync_wallet_,
        address native_token_eth_in_zksync_
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        current_order_id = 0;
        ethereum_payment_registry = ethereum_payment_registry_;
        mm_ethereum_wallet = mm_ethereum_wallet_;
        mm_zksync_wallet = mm_zksync_wallet_;
        native_token_eth_in_zksync = native_token_eth_in_zksync_;
    }

    //functions
    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}
