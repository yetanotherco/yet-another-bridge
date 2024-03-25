# Escrow.sol

[Escrow.sol](../../../contracts/zksync/contracts/escrow.sol) is a Smart Contract written in Solidity that resides in Ethereum's L2 [ZKSync](https://zksync.io/), and is our implementation of our bridge's [Escrow](./Escrow.md) entity for this L2.

## How does a User set a new order?

This contract recieves User's new orders with the function:
```solidity
    function set_order(address recipient_address, uint256 fee) public payable whenNotPaused returns (uint256)
```

Which returns the new order's ID.

## How does a MM detect a User's new order?

When a new order is set, the following SetOrder Event is emitted, detectable by MM's:
```solidity
event SetOrder(uint256 order_id, address recipient_address, uint256 amount, uint256 fee);
```

## How does a MM claim his payment?

The `claim_payment` function is called, only by our [Payment Registry](../payment_registry.md), in order for the MM to retrieve its payment from the Escrow:
```solidity
function claim_payment(
    uint256 order_id,
    address recipient_address,
    uint256 amount
) public whenNotPaused
```


