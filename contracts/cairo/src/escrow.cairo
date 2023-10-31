#[derive(Serde, Drop, starknet::Store)]
struct Order {
    #[key]
    order_id: u256,
    recipient_address: felt252,
    amount: u256,
    fee: u64,
    expiry: u64
}

#[starknet::interface]
trait IEscrow<ContractState> {
    fn get_order(self: @ContractState, order_id: u256) -> Order;

    fn set_order(ref self: ContractState, order_id: u256, order: Order);

    fn cancel_order(ref self: ContractState, order_id: u256);

    fn get_order_used(self: @ContractState, order_id: u256) -> bool;

    fn get_reservation(self: @ContractState, order_id: u256) -> felt252;

    fn set_reservation(ref self: ContractState, order_id: u256, address: felt252);

    fn withdraw(
        ref self: ContractState,
        order_id: u256,
        block: u256,
        slot: u256
    );
}

#[starknet::contract]
mod Escrow {
    use super::{IEscrow, Order};

    use yab::interfaces::IERC20::{
        IERC20Dispatcher, IERC20DispatcherTrait
    };
    use yab::interfaces::IEVMFactsRegistry::{
        IEVMFactsRegistryDispatcher, IEVMFactsRegistryDispatcherTrait
    };

    // https://github.com/starknet-io/starknet-addresses
    // MAINNET = GOERLI = GOERLI2
    // 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    const NATIVE_TOKEN: felt252 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;
    const HERODOTUS_FACTS_REGISTRY: felt252 = 0x02c8c8543a57ac55d76b3d8a2051cd5e4111dd65ca2cfc0444d8f87a0df46faf;
    const ETH_TRANSFER_CONTRACT: felt252 = 0x0;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Withdraw: Withdraw,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw {
        #[key]
        order_id: u256,
        address: felt252,
        amount: u256,
    }

    #[storage]
    struct Storage {
        current_order_id: u256,
        orders: LegacyMap::<u256, Order>,
        orders_used: LegacyMap::<u256, bool>,
        reservations: LegacyMap::<u256, felt252>
    }

    #[constructor]
    fn constructor(ref self: ContractState, yab_eth: felt252) {
        self.current_order_id.write(0);
    }

    #[external(v0)]
    impl Escrow of IEscrow<ContractState> {
        fn get_order(self: @ContractState, order_id: u256) -> Order {
            self.orders.read(order_id)
        }

        fn set_order(ref self: ContractState, order_id: u256, order: Order) {
            // TODO expiry can't be less than 24h
            self.orders.write(order_id, order);
        }

        fn cancel_order(ref self: ContractState, order_id: u256) {
            // TODO the order can be cancelled if no one reserved yet
            // the user can retrieve all the funds without waiting for the expiry
        }

        fn get_order_used(self: @ContractState, order_id: u256) -> bool {
            self.orders_used.read(order_id)
        }

        fn get_reservation(self: @ContractState, order_id: u256) -> felt252 {
            self.reservations.read(order_id)
        }

        fn set_reservation(ref self: ContractState, order_id: u256, address: felt252) {
            // TODO validate if the non used == 0x0
            assert(self.reservations.read(order_id) == 0x0, 'Order already reserved');
            // TODO
            // we allow reservations other than the caller address
            // stake amount to avoid DoS
            self.reservations.write(order_id, address);
        }

        fn withdraw(
            ref self: ContractState,
            order_id: u256,
            block: u256,
            slot: u256,
        ) {
            assert(!self.orders_used.read(order_id), 'Order already withdrawed');

            // Read transfer info from the facts registry
            // struct TransferInfo {
            //     uint256 destAddress;
            //     uint128 amount;
            //     bool isUsed;
            // }

            let mut slot_1 = slot.clone();
            // TODO confirm this, probably it's not true
            slot_1 += 1;

            let slot_0 = slot;

            // Slot n contains the address of the recipient
            let slot_0_value = IEVMFactsRegistryDispatcher {
                contract_address: HERODOTUS_FACTS_REGISTRY.try_into().unwrap()
            }
                .get_slot_value(
                    ETH_TRANSFER_CONTRACT,
                    block,
                    slot_0,
                ).unwrap();
            let address: felt252 = slot_0_value.try_into().expect('Invalid address');

            // Slot n+1 contains the amount and isUsed
            let amount = IEVMFactsRegistryDispatcher {
                contract_address: HERODOTUS_FACTS_REGISTRY.try_into().unwrap()
            }
                .get_slot_value(
                    ETH_TRANSFER_CONTRACT,
                    block,
                    slot_1,
                ).unwrap();

            self.orders_used.write(order_id, true);

            // Withdraw
            let recipient = self.reservations.read(order_id);

            // TODO
            // - add fee
            // - confirm slot values against local order
            IERC20Dispatcher { contract_address: NATIVE_TOKEN.try_into().unwrap() }.transfer(recipient.try_into().unwrap(), amount);

            self.emit(Withdraw {
                order_id,
                address: recipient,
                amount
            });
        }
    }
}
