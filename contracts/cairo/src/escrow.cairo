use starknet::{ContractAddress, EthAddress};

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Order {
    recipient_address: EthAddress,
    amount: u256
}

#[starknet::interface]
trait IEscrow<ContractState> {
    fn get_order(self: @ContractState, order_id: u256) -> Order;

    fn set_order(ref self: ContractState, order: Order) -> u256;

    fn cancel_order(ref self: ContractState, order_id: u256);

    fn get_order_used(self: @ContractState, order_id: u256) -> bool;

    fn withdraw(ref self: ContractState, order_id: u256, block: u256, slot: u256);

    fn get_herodotus_facts_registry_contract(self: @ContractState) -> ContractAddress;
    fn get_eth_transfer_contract(self: @ContractState) -> EthAddress;
    fn get_mm_ethereum_contract(self: @ContractState) -> EthAddress;
    fn get_mm_starknet_contract(self: @ContractState) -> ContractAddress;
    fn set_herodotus_facts_registry_contract(
        ref self: ContractState, new_contract: ContractAddress
    );
    fn set_eth_transfer_contract(ref self: ContractState, new_contract: EthAddress);
    fn set_mm_ethereum_contract(ref self: ContractState, new_contract: EthAddress);
    fn set_mm_starknet_contract(ref self: ContractState, new_contract: ContractAddress);
}

#[starknet::contract]
mod Escrow {
    use super::{IEscrow, Order};

    use starknet::{ContractAddress, EthAddress, get_caller_address, get_contract_address};

    use openzeppelin::access::ownable::interface::IOwnable;
    use openzeppelin::access::ownable::ownable::Ownable;

    use yab::interfaces::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yab::interfaces::IEVMFactsRegistry::{
        IEVMFactsRegistryDispatcher, IEVMFactsRegistryDispatcherTrait
    };

    // https://github.com/starknet-io/starknet-addresses
    // MAINNET = GOERLI = GOERLI2
    // 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    // const NATIVE_TOKEN: felt252 =
    //     0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Withdraw: Withdraw,
        SetOrder: SetOrder
    }

    #[derive(Drop, starknet::Event)]
    struct SetOrder {
        order_id: u256,
        recipient_address: EthAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw {
        order_id: u256,
        address: ContractAddress,
        amount: u256,
    }

    #[storage]
    struct Storage {
        current_order_id: u256,
        orders: LegacyMap::<u256, Order>,
        orders_used: LegacyMap::<u256, bool>,
        herodotus_facts_registry_contract: ContractAddress,
        eth_transfer_contract: EthAddress, // our transfer contract in L1
        mm_ethereum_wallet: EthAddress,
        mm_starknet_wallet: ContractAddress,
        native_token_eth_starknet: ContractAddress
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        herodotus_facts_registry_contract: ContractAddress,
        eth_transfer_contract: EthAddress,
        mm_ethereum_wallet: EthAddress,
        mm_starknet_wallet: ContractAddress,
        native_token_eth_starknet: ContractAddress
    ) {
        let mut unsafe_state = Ownable::unsafe_new_contract_state();
        Ownable::InternalImpl::initializer(ref unsafe_state, get_caller_address());

        self.current_order_id.write(0);
        self.herodotus_facts_registry_contract.write(herodotus_facts_registry_contract);
        self.eth_transfer_contract.write(eth_transfer_contract);
        self.mm_ethereum_wallet.write(mm_ethereum_wallet);
        self.mm_starknet_wallet.write(mm_starknet_wallet);
        self.native_token_eth_starknet.write(native_token_eth_starknet);
    }

    #[external(v0)]
    impl Escrow of IEscrow<ContractState> {
        fn get_order(self: @ContractState, order_id: u256) -> Order {
            self.orders.read(order_id)
        }

        fn set_order(ref self: ContractState, order: Order) -> u256 {
            // TODO expiry can't be less than 24h

            let mut order_id = self.current_order_id.read();
            self.orders.write(order_id, order);
            self.orders_used.write(order_id, false);

            // TODO: add allowance ?

            IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
                .transferFrom(get_caller_address(), get_contract_address(), order.amount);

            self
                .emit(
                    SetOrder {
                        order_id, recipient_address: order.recipient_address, amount: order.amount
                    }
                );

            self.current_order_id.write(order_id + 1);
            order_id
        }

        fn cancel_order(
            ref self: ContractState, order_id: u256
        ) { // TODO the order can be cancelled if no one reserved yet
        // the user can retrieve all the funds without waiting for the expiry
        }

        fn get_order_used(self: @ContractState, order_id: u256) -> bool {
            self.orders_used.read(order_id)
        }

        fn withdraw(ref self: ContractState, order_id: u256, block: u256, slot: u256) {
            assert(
                self.mm_starknet_wallet.read() == get_caller_address(), 'Only MM_STARKNET_CONTRACT'
            );
            assert(!self.orders_used.read(order_id), 'Order already withdrawed');

            // Read transfer info from the facts registry
            // struct TransferInfo {
            //     uint256 destAddress;
            //     uint256 amount;
            //     bool isUsed;
            // }

            let mut slot_1 = slot.clone();
            slot_1 += 2;

            let slot_0 = slot;

            // Slot n contains the address of the recipient
            let slot_0_value = IEVMFactsRegistryDispatcher {
                contract_address: self.herodotus_facts_registry_contract.read()
            }
                .get_slot_value(self.eth_transfer_contract.read().into(), block, slot_0)
                .unwrap();

            let recipient_address: felt252 = slot_0_value
                .try_into()
                .expect('Invalid address parse felt252');
            let recipient_address: EthAddress = recipient_address
                .try_into()
                .expect('Invalid address parse EthAddres');

            let order = self.orders.read(order_id);
            assert(order.recipient_address == recipient_address, 'recipient_address not match L1');

            // Slot n+1 contains the amount and isUsed
            let amount = IEVMFactsRegistryDispatcher {
                contract_address: self.herodotus_facts_registry_contract.read()
            }
                .get_slot_value(self.eth_transfer_contract.read().into(), block, slot_1)
                .unwrap();

            assert(order.amount == amount, 'amount not match L1');

            self.orders_used.write(order_id, true);

            IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
                .transfer(self.mm_starknet_wallet.read(), amount);

            self.emit(Withdraw { order_id, address: self.mm_starknet_wallet.read(), amount });
        }

        fn get_herodotus_facts_registry_contract(self: @ContractState) -> ContractAddress {
            self.herodotus_facts_registry_contract.read()
        }

        fn get_eth_transfer_contract(self: @ContractState) -> EthAddress {
            self.eth_transfer_contract.read()
        }

        fn get_mm_ethereum_contract(self: @ContractState) -> EthAddress {
            self.mm_ethereum_wallet.read()
        }

        fn get_mm_starknet_contract(self: @ContractState) -> ContractAddress {
            self.mm_starknet_wallet.read()
        }

        fn set_herodotus_facts_registry_contract(
            ref self: ContractState, new_contract: ContractAddress
        ) {
            let unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::InternalImpl::assert_only_owner(@unsafe_state);
            self.herodotus_facts_registry_contract.write(new_contract);
        }

        fn set_eth_transfer_contract(ref self: ContractState, new_contract: EthAddress) {
            let unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::InternalImpl::assert_only_owner(@unsafe_state);
            self.eth_transfer_contract.write(new_contract);
        }

        fn set_mm_ethereum_contract(ref self: ContractState, new_contract: EthAddress) {
            let unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::InternalImpl::assert_only_owner(@unsafe_state);
            self.mm_ethereum_wallet.write(new_contract);
        }

        fn set_mm_starknet_contract(ref self: ContractState, new_contract: ContractAddress) {
            let unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::InternalImpl::assert_only_owner(@unsafe_state);
            self.mm_starknet_wallet.write(new_contract);
        }
    }

    #[l1_handler]
    fn withdraw_fallback(
        ref self: ContractState,
        from_address: felt252,
        order_id: u256,
        recipient_address: EthAddress,
        amount: u256) {
        let eth_transfer_contract_felt: felt252 = self.eth_transfer_contract.read().into();
        assert(
            eth_transfer_contract_felt == from_address, 'Only ETH_TRANSFER_CONTRACT'
        );
        assert(!self.orders_used.read(order_id), 'Order already withdrawed');

        let order = self.orders.read(order_id);
        assert(order.recipient_address == recipient_address, 'recipient_address not match L1');
        assert(order.amount == amount, 'amount not match L1');

        self.orders_used.write(order_id, true);

        IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
            .transfer(self.mm_starknet_wallet.read(), amount);

        self.emit(Withdraw { order_id, address: self.mm_starknet_wallet.read(), amount });
    }

    // Ownable

    #[external(v0)]
    impl OwnableImpl of IOwnable<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            let unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::OwnableImpl::owner(@unsafe_state)
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            let mut unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::OwnableImpl::transfer_ownership(ref unsafe_state, new_owner)
        }

        fn renounce_ownership(ref self: ContractState) {
            let mut unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::OwnableImpl::renounce_ownership(ref unsafe_state)
        }
    }
}
