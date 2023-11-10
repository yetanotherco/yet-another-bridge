#[starknet::contract]
mod EVMFactsRegistry {
    use yab::interfaces::IEVMFactsRegistry::IEVMFactsRegistry;

    #[storage]
    struct Storage {
        slots: LegacyMap::<u256, u256>
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.slots.write(0, 12345); // mock recipient_address
        self.slots.write(2, 500); // mock amount
    }

    #[external(v0)]
    impl EVMFactsRegistry of IEVMFactsRegistry<ContractState> {
        fn get_slot_value(
            self: @ContractState, account: felt252, block: u256, slot: u256
        ) -> Option<u256> {
            Option::Some(self.slots.read(slot))
        }
    }
}
