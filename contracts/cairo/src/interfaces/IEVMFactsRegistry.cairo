#[starknet::interface]
trait IEVMFactsRegistry<TContractState> {
    fn get_slot_value(
        self: @TContractState, account: felt252, block: u256, slot: u256
    ) -> Option<u256>;
}
