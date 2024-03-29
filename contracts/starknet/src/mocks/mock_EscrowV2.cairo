use starknet::{ContractAddress, ClassHash, EthAddress};

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Order {
    recipient_address: EthAddress,
    amount: u256,
    fee: u256
}

#[starknet::interface]
trait IEscrowV2<ContractState> {
    fn get_orderV2(self: @ContractState, order_id: u256) -> Order;

    fn set_orderV2(ref self: ContractState, order: Order) -> u256;

    fn cancel_order(ref self: ContractState, order_id: u256);

    fn get_order_used(self: @ContractState, order_id: u256) -> bool;

    fn get_order_fee(self: @ContractState, order_id: u256) -> u256;

    fn withdraw(ref self: ContractState, order_id: u256, block: u256, slot: u256);

    fn get_herodotus_facts_registry_contract(self: @ContractState) -> ContractAddress;
    fn get_eth_transfer_contract(self: @ContractState) -> EthAddress;
    fn get_mm_ethereum_contract(self: @ContractState) -> EthAddress;
    fn get_mm_starknet_contract(self: @ContractState) -> ContractAddress;
    fn set_herodotus_facts_registry_contract(
        ref self: ContractState, new_contract: ContractAddress
    );
    fn get_mm_starknet_contractv2(self: @ContractState) -> ContractAddress;
    fn set_herodotus_facts_registry_contractv2(
        ref self: ContractState, new_contract: ContractAddress
    );
    fn set_eth_transfer_contract(ref self: ContractState, new_contract: EthAddress);
    fn set_mm_ethereum_contract(ref self: ContractState, new_contract: EthAddress);
    fn set_mm_starknet_contract(ref self: ContractState, new_contract: ContractAddress);

    fn new_mock_function(self: @ContractState) -> bool;
}

#[starknet::contract]
mod EscrowV2 {
    use super::{IEscrowV2, Order};

    use openzeppelin::{
        access::ownable::OwnableComponent,
        upgrades::{UpgradeableComponent, interface::IUpgradeable}
    };
    use starknet::{
        ContractAddress, EthAddress, ClassHash, get_caller_address, get_contract_address,
        get_block_timestamp
    };

    use yab::interfaces::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yab::interfaces::IEVMFactsRegistry::{
        IEVMFactsRegistryDispatcher, IEVMFactsRegistryDispatcherTrait
    };

    /// Components
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    /// (Ownable)
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// (Upgradeable)
    impl InternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // https://github.com/starknet-io/starknet-addresses
    // MAINNET = GOERLI = GOERLI2
    // 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    // const NATIVE_TOKEN: felt252 =
    //     0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Withdraw: Withdraw,
        SetOrder: SetOrder,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct SetOrder {
        order_id: u256,
        recipient_address: EthAddress,
        amount: u256,
        fee: u256
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
        orders_senders: LegacyMap::<u256, ContractAddress>,
        orders_timestamps: LegacyMap::<u256, u64>,
        herodotus_facts_registry_contract: ContractAddress,
        eth_transfer_contract: EthAddress, // our transfer contract in L1
        mm_ethereum_wallet: EthAddress,
        mm_starknet_wallet: ContractAddress,
        native_token_eth_starknet: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        herodotus_facts_registry_contract: ContractAddress,
        eth_transfer_contract: EthAddress,
        mm_ethereum_wallet: EthAddress,
        mm_starknet_wallet: ContractAddress,
        native_token_eth_starknet: ContractAddress
    ) {
        self.ownable.initializer(owner);

        self.current_order_id.write(0);
        self.herodotus_facts_registry_contract.write(herodotus_facts_registry_contract);
        self.eth_transfer_contract.write(eth_transfer_contract);
        self.mm_ethereum_wallet.write(mm_ethereum_wallet);
        self.mm_starknet_wallet.write(mm_starknet_wallet);
        self.native_token_eth_starknet.write(native_token_eth_starknet);
    }

    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[external(v0)]
    impl Escrow of IEscrowV2<ContractState> {
        fn get_orderV2(self: @ContractState, order_id: u256) -> Order {
            self.orders.read(order_id)
        }

        fn set_orderV2(ref self: ContractState, order: Order) -> u256 {
            assert(order.amount > 0, 'Amount must be greater than 0');

            let mut order_id = self.current_order_id.read();
            self.orders.write(order_id, order);
            self.orders_used.write(order_id, false);
            self.orders_senders.write(order_id, get_caller_address());
            self.orders_timestamps.write(order_id, get_block_timestamp());
            let payment_amount = order.amount + order.fee;

            IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
                .transferFrom(get_caller_address(), get_contract_address(), payment_amount);

            self
                .emit(
                    SetOrder {
                        order_id,
                        recipient_address: order.recipient_address,
                        amount: order.amount,
                        fee: order.fee
                    }
                );

            self.current_order_id.write(order_id + 1);
            order_id
        }

        fn cancel_order(ref self: ContractState, order_id: u256) {
            assert(!self.orders_used.read(order_id), 'Order already withdrawed');
            assert(
                get_block_timestamp() - self.orders_timestamps.read(order_id) < 43200,
                'Didnt passed enough time'
            );

            let sender = self.orders_senders.read(order_id);
            assert(sender == get_caller_address(), 'Only sender allowed');
            let order = self.orders.read(order_id);
            let payment_amount = order.amount + order.fee;

            IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
                .transfer(sender, payment_amount);
        }

        fn get_order_used(self: @ContractState, order_id: u256) -> bool {
            self.orders_used.read(order_id)
        }

        fn get_order_fee(self: @ContractState, order_id: u256) -> u256 {
            let order: Order = self.orders.read(order_id);
            order.fee
        }

        fn withdraw(ref self: ContractState, order_id: u256, block: u256, slot: u256) {
            assert(!self.orders_used.read(order_id), 'Order already withdrawed');

            // Read transfer info from the facts registry
            // struct TransferInfo {
            //     uint256 destAddress;
            //     uint256 amount;
            //     bool isUsed;
            // }

            let mut slot_1 = slot.clone();
            slot_1 += 1;

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
            let payment_amount = order.amount + order.fee;

            IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
                .transfer(self.mm_starknet_wallet.read(), payment_amount);

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
            self.ownable.assert_only_owner();
            self.herodotus_facts_registry_contract.write(new_contract);
        }

        fn get_mm_starknet_contractv2(self: @ContractState) -> ContractAddress {
            self.mm_starknet_wallet.read()
        }

        fn set_herodotus_facts_registry_contractv2(
            ref self: ContractState, new_contract: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            self.herodotus_facts_registry_contract.write(new_contract);
        }

        fn set_eth_transfer_contract(ref self: ContractState, new_contract: EthAddress) {
            self.ownable.assert_only_owner();
            self.eth_transfer_contract.write(new_contract);
        }

        fn set_mm_ethereum_contract(ref self: ContractState, new_contract: EthAddress) {
            self.ownable.assert_only_owner();
            self.mm_ethereum_wallet.write(new_contract);
        }

        fn set_mm_starknet_contract(ref self: ContractState, new_contract: ContractAddress) {
            self.ownable.assert_only_owner();   
            self.mm_starknet_wallet.write(new_contract);
        }

        fn new_mock_function(self: @ContractState) -> bool{
            true
        }

    }

    #[l1_handler]
    fn withdraw_fallback(
        ref self: ContractState,
        from_address: felt252,
        order_id: u256,
        recipient_address: EthAddress,
        amount: u256
    ) {
        let eth_transfer_contract_felt: felt252 = self.eth_transfer_contract.read().into();
        assert(eth_transfer_contract_felt == from_address, 'Only ETH_TRANSFER_CONTRACT');
        assert(!self.orders_used.read(order_id), 'Order already withdrawed');

        let order = self.orders.read(order_id);
        assert(order.recipient_address == recipient_address, 'recipient_address not match L1');
        assert(order.amount == amount, 'amount not match L1');

        self.orders_used.write(order_id, true);
        let payment_amount = order.amount + order.fee;

        IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
            .transfer(self.mm_starknet_wallet.read(), payment_amount);

        self.emit(Withdraw { order_id, address: self.mm_starknet_wallet.read(), amount });
    }
}
