use starknet::{ContractAddress, ClassHash, EthAddress};

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Order {
    recipient_address: EthAddress,
    amount: u256,
    fee: u256
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct OrderERC20 {
    recipient_address: EthAddress,
    amount_l2: u256,
    amount_l1: u256,
    fee: u256,
    l2_erc20_address: ContractAddress,
    l1_erc20_address: EthAddress
}

#[starknet::interface]
trait IEscrow<ContractState> {
    fn get_order(self: @ContractState, order_id: u256) -> Order;
    fn get_order_erc20(self: @ContractState, order_id: u256) -> OrderERC20;

    fn set_order(ref self: ContractState, order: Order) -> u256;
    fn set_order_erc20(ref self: ContractState, order_erc20: OrderERC20) -> u256;

    fn get_order_pending(self: @ContractState, order_id: u256) -> bool;

    fn get_order_fee(self: @ContractState, order_id: u256) -> u256;
    fn get_order_erc20_fee(self: @ContractState, order_id: u256) -> u256;

    fn get_eth_transfer_contract(self: @ContractState) -> EthAddress;
    fn get_mm_ethereum_wallet(self: @ContractState) -> EthAddress;
    fn get_mm_starknet_contract(self: @ContractState) -> ContractAddress;

    fn set_eth_transfer_contract(ref self: ContractState, new_contract: EthAddress);
    fn set_mm_ethereum_wallet(ref self: ContractState, new_contract: EthAddress);
    fn set_mm_starknet_contract(ref self: ContractState, new_contract: ContractAddress);

    fn pause(ref self: ContractState);
    fn unpause(ref self: ContractState);
}

#[starknet::contract]
mod Escrow {
    use core::traits::Into;
    use super::{IEscrow, Order, OrderERC20};

    use openzeppelin::{
        access::ownable::OwnableComponent,
        upgrades::{UpgradeableComponent, interface::IUpgradeable},
        security::PausableComponent,
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
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);

    /// (Ownable)
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// (Upgradeable)
    impl InternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // Pausable
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    // https://github.com/starknet-io/starknet-addresses
    // MAINNET = GOERLI = GOERLI2
    // 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    // const NATIVE_TOKEN: felt252 =
    //     0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ClaimPayment: ClaimPayment,
        ClaimPaymentERC20: ClaimPaymentERC20,
        SetOrder: SetOrder,
        SetOrderERC20: SetOrderERC20,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct SetOrder {
        order_id: u256,
        recipient_address: EthAddress,
        amount: u256,
        fee: u256
    }

    #[derive(Drop, starknet::Event)]
    struct SetOrderERC20 {
        order_id: u256,
        recipient_address: EthAddress,
        amount_l2: u256,
        amount_l1: u256,
        fee: u256,
        l2_erc20_address: ContractAddress,
        l1_erc20_address: EthAddress
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimPayment {
        order_id: u256,
        address: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimPaymentERC20 {
        order_id: u256,
        address: ContractAddress,
        amount_l2: u256,
        fee: u256,
        l2_erc20_address: ContractAddress
    }

    #[storage]
    struct Storage {
        current_order_id: u256,
        orders: LegacyMap::<u256, Order>,
        orders_erc20: LegacyMap::<u256, OrderERC20>,
        orders_pending: LegacyMap::<u256, bool>,
        orders_senders: LegacyMap::<u256, ContractAddress>,
        orders_timestamps: LegacyMap::<u256, u64>,
        eth_transfer_contract: EthAddress, // our transfer (PaymentRegistry) contract in L1
        mm_ethereum_wallet: EthAddress,
        mm_starknet_wallet: ContractAddress,
        native_token_eth_starknet: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        eth_transfer_contract: EthAddress,
        mm_ethereum_wallet: EthAddress,
        mm_starknet_wallet: ContractAddress,
        native_token_eth_starknet: ContractAddress
    ) {
        self.ownable.initializer(owner);

        self.current_order_id.write(0);
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
    impl Escrow of IEscrow<ContractState> {
        fn get_order(self: @ContractState, order_id: u256) -> Order {
            self.orders.read(order_id)
        }

        fn get_order_erc20(self: @ContractState, order_id: u256) -> OrderERC20 {
            self.orders_erc20.read(order_id)
        }

        fn set_order(ref self: ContractState, order: Order) -> u256 {
            self.pausable.assert_not_paused();
            assert(order.amount > 0, 'Amount must > 0');

            let payment_amount = order.amount + order.fee;
            let dispatcher = IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() };
            assert(dispatcher.allowance(get_caller_address(), get_contract_address()) >= payment_amount, 'Not enough allowance');
            assert(dispatcher.balanceOf(get_caller_address()) >= payment_amount, 'Not enough balance');

            let mut order_id = self.current_order_id.read();
            self.orders.write(order_id, order);
            self.orders_pending.write(order_id, true);
            self.orders_senders.write(order_id, get_caller_address());
            self.orders_timestamps.write(order_id, get_block_timestamp());
            self.current_order_id.write(order_id + 1);

            dispatcher.transferFrom(get_caller_address(), get_contract_address(), payment_amount);

            self
                .emit(
                    SetOrder {
                        order_id,
                        recipient_address: order.recipient_address,
                        amount: order.amount,
                        fee: order.fee
                    }
                );

            order_id
        }


    // Recieves in order.fee the total fee for MM
    //          in order.amount_l2, the total tokens he will give to MM in L2
    //          in order.amount_l1, the total tokens he will receive from MM in L1
    //          this way, the user is able to bridge tokens cross-erc20, giving, for example, WETH and recieving USDC
    //          the extra computational costs of this is neglegible: only 1 extra param and 1 extra uint256 stored per ERC20 order in L2, and NO EXTRA COSTS in L1
        fn set_order_erc20(ref self: ContractState, order_erc20: OrderERC20) -> u256 {
            self.pausable.assert_not_paused();
            assert(order_erc20.amount_l2 > 0, 'Amount_l2 must > 0'); //in ERC20
            assert(order_erc20.amount_l1 > 0, 'Amount_l1 must > 0'); //in ERC20
            assert(order_erc20.fee > 0, 'Fee must > 0'); //in ETH

            // Fee (ETH):
            let eth_dispatcher = IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() };
            assert(eth_dispatcher.allowance(get_caller_address(), get_contract_address()) >= order_erc20.fee, 'Need allowance for fee');
            assert(eth_dispatcher.balanceOf(get_caller_address()) >= order_erc20.fee, 'Need balance for fee');

            // Amount (ERC20):
            let erc20_dispatcher = IERC20Dispatcher { contract_address: order_erc20.l2_erc20_address };
            assert(erc20_dispatcher.allowance(get_caller_address(), get_contract_address()) >= order_erc20.amount_l2, 'Need allowance for amount_l2');
            assert(erc20_dispatcher.balanceOf(get_caller_address()) >= order_erc20.amount_l2, 'Need balance for amount_l2');

            let mut order_id = self.current_order_id.read();
            self.orders_erc20.write(order_id, order_erc20);
            self.orders_pending.write(order_id, true);
            self.orders_senders.write(order_id, get_caller_address());
            self.orders_timestamps.write(order_id, get_block_timestamp());
            self.current_order_id.write(order_id + 1);

            eth_dispatcher.transferFrom(get_caller_address(), get_contract_address(), order_erc20.fee);
            erc20_dispatcher.transferFrom(get_caller_address(), get_contract_address(), order_erc20.amount_l2);

            self
                .emit(
                    SetOrderERC20 {
                        order_id,
                        recipient_address: order_erc20.recipient_address,
                        amount_l2: order_erc20.amount_l2,
                        amount_l1: order_erc20.amount_l1,
                        fee: order_erc20.fee,
                        l2_erc20_address: order_erc20.l2_erc20_address,
                        l1_erc20_address: order_erc20.l1_erc20_address
                    }
                );

            order_id
        }

        fn get_order_pending(self: @ContractState, order_id: u256) -> bool {
            self.orders_pending.read(order_id)
        }

        fn get_order_fee(self: @ContractState, order_id: u256) -> u256 {
            let order: Order = self.orders.read(order_id);
            order.fee
        }

        fn get_order_erc20_fee(self: @ContractState, order_id: u256) -> u256 {
            let order_erc20: OrderERC20 = self.orders_erc20.read(order_id);
            order_erc20.fee
        }

        fn get_eth_transfer_contract(self: @ContractState) -> EthAddress {
            self.eth_transfer_contract.read()
        }

        fn get_mm_ethereum_wallet(self: @ContractState) -> EthAddress {
            self.mm_ethereum_wallet.read()
        }

        fn get_mm_starknet_contract(self: @ContractState) -> ContractAddress {
            self.mm_starknet_wallet.read()
        }

        fn set_eth_transfer_contract(ref self: ContractState, new_contract: EthAddress) {
            self.pausable.assert_not_paused();
            self.ownable.assert_only_owner();
            self.eth_transfer_contract.write(new_contract);
        }

        fn set_mm_ethereum_wallet(ref self: ContractState, new_contract: EthAddress) {
            self.pausable.assert_not_paused();
            self.ownable.assert_only_owner();
            self.mm_ethereum_wallet.write(new_contract);
        }

        fn set_mm_starknet_contract(ref self: ContractState, new_contract: ContractAddress) {
            self.pausable.assert_not_paused();
            self.ownable.assert_only_owner();
            self.mm_starknet_wallet.write(new_contract);
        }

        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable._pause();
        }

        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable._unpause();
        }
    }

    #[l1_handler]
    fn claim_payment(
        ref self: ContractState,
        from_address: felt252,
        order_id: u256,
        recipient_address: EthAddress,
        amount: u256
    ) {
        self.pausable.assert_not_paused();
        let eth_transfer_contract_felt: felt252 = self.eth_transfer_contract.read().into();
        assert(from_address == eth_transfer_contract_felt, 'Only PAYMENT_REGISTRY_CONTRACT');

        _claim_payment(ref self, from_address, order_id, recipient_address, amount);
    }

    #[l1_handler]
    fn claim_payment_erc20(
        ref self: ContractState,
        from_address: felt252,
        order_id: u256,
        recipient_address: EthAddress,
        amount_l1: u256,
        l1_erc20_address: EthAddress
    ) {
        self.pausable.assert_not_paused();
        let eth_transfer_contract_felt: felt252 = self.eth_transfer_contract.read().into();
        assert(from_address == eth_transfer_contract_felt, 'Only PAYMENT_REGISTRY_CONTRACT');

        _claim_payment_erc20(ref self, from_address, order_id, recipient_address, amount_l1, l1_erc20_address);
    }

    #[l1_handler]
    fn claim_payment_batch(
        ref self: ContractState,
        from_address: felt252,
        orders: Array<(u256, EthAddress, u256)>
    ) {
        let eth_transfer_contract_felt: felt252 = self.eth_transfer_contract.read().into();
        assert(from_address == eth_transfer_contract_felt, 'Only PAYMENT_REGISTRY_CONTRACT');

        let mut idx = 0;

        loop {
            if idx >= orders.len() {
                break;
            }

            let (order_id, recipient_address, amount) = *orders.at(idx);

            _claim_payment(ref self, from_address, order_id, recipient_address, amount);

            idx += 1;
        };
    }

    fn _claim_payment(
        ref self: ContractState,
        from_address: felt252,
        order_id: u256,
        recipient_address: EthAddress,
        amount: u256
    ) {
        assert(self.orders_pending.read(order_id), 'Order withdrew or nonexistent');
        
        let order = self.orders.read(order_id);
        assert(order.recipient_address == recipient_address, 'recipient_address not match L1');
        assert(order.amount == amount, 'amount not match L1');
        
        self.orders_pending.write(order_id, false);
        let payment_amount = order.amount + order.fee;
        
        // TODO: In batch, it might be best to transfer all at once
        IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
            .transfer(self.mm_starknet_wallet.read(), payment_amount);
            
        self.emit(ClaimPayment { order_id, address: self.mm_starknet_wallet.read(), amount });
    }

    fn _claim_payment_erc20(
        ref self: ContractState,
        from_address: felt252,
        order_id: u256,
        recipient_address: EthAddress,
        amount_l1: u256,
        l1_erc20_address: EthAddress
    ) {
        assert(self.orders_pending.read(order_id), 'Order withdrew or nonexistent');
        
        let order_erc20 = self.orders_erc20.read(order_id);
        assert(order_erc20.recipient_address == recipient_address, 'recipient_address not match L1');
        assert(order_erc20.amount_l1 == amount_l1, 'amount_l1 not match L1');
        assert(order_erc20.l1_erc20_address == l1_erc20_address, 'l1_erc20_address not match L1');

        self.orders_pending.write(order_id, false);

        //Fee (ETH):
        IERC20Dispatcher { contract_address: self.native_token_eth_starknet.read() }
            .transfer(self.mm_starknet_wallet.read(), order_erc20.fee);

        //Amount (ERC20):
        IERC20Dispatcher { contract_address: order_erc20.l2_erc20_address }
            .transfer(self.mm_starknet_wallet.read(), order_erc20.amount_l2);

        self.emit(ClaimPaymentERC20 { order_id, address: self.mm_starknet_wallet.read(), amount_l2: order_erc20.amount_l2, fee: order_erc20.fee, l2_erc20_address: order_erc20.l2_erc20_address } );
    }
}
