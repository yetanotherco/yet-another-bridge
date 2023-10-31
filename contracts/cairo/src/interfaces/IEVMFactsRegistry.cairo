#[starknet::interface]
trait IEVMFactsRegistry<T> {
    fn get_slot_value(
        self: T,
        account: felt252,
        block: u256,
        slot: u256
    ) -> Option<u256>;
}
