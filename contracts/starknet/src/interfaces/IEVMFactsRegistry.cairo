#[starknet::interface]
trait IEVMFactsRegistry<TState> {
    fn get_slot_value(self: @TState, account: felt252, block: u256, slot: u256) -> Option<u256>;
}
