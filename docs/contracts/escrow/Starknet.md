# Escrow.cairo

[Escrow.cairo](../../contracts/cairo/src/escrow.cairo) is a Smart Contract written in Cairo that resides in Ethereum's L2 [Starknet](https://www.starknet.io/en), and is our implementation of our bridge's [Escrow](./Escrow.md) entity for this L2.

## How does a User set a new order?

This contract recieves User's new orders with the function:
```
fn set_order(ref self: ContractState, order: Order) -> u256
```

Which recieves an `Order` structure:
```cairo
struct Order {
    recipient_address: EthAddress,
    amount: u256,
    fee: u256
}
```

And returns the new order's ID.

## How does a MM detect a User's new order?

When a new order is set, the following SetOrder Event is emitted, detectable by MM's:
```cairo
struct SetOrder {
    order_id: u256,
    recipient_address: EthAddress,
    amount: u256,
    fee: u256
}
```

## How does a MM claim his payment?

The `claim_payment` function is called, only by our [Payment Registry](../payment_registry.md), in order for the MM to retrieve its payment from the Escrow:
```cairo
#[l1_handler]
fn claim_payment(
    ref self: ContractState,
    from_address: felt252,
    order_id: u256,
    recipient_address: EthAddress,
    amount: u256
)
```
