# Escrow

The Escrow is a Smart Contract that can reside in any Ethereum L2.

This contract is responsible for receiving Users' payments in L2, and liberating them 
to the MM when, and only when, the MM has proved the payment in L1.

This contract has a storage of all orders. When a new order is made, by calling the 
`set_order` function, this contract reads the new order's details, verifies the Order 
is acceptable, and if so, stores this data and accepts from the sender the 
appropriate amount of tokens. 

An Order's details are:
- The address where the User wants to receive the transaction on L1
- The amount he wants to receive
- The amount he is willing to give the MM as fee to concrete the bridge process

Once Escrow has accepted the new order, it will emit a `SetOrder` event, containing 
this information so that MMs can decide if they want to accept this offer.

The user must wait until an MM picks its order, which should be almost instantaneous 
if the transfer fee is the suggested one.

After an MM consolidates an order, Escrow will receive a `claim_payment` call from the Payment Registry, containing the information about how MM has indeed bridged the funds 
to the User's L1 address, and where does MM want to receive it's L2 tokens.

Escrow will then cross-check this information to its own records, and if everything is in 
check, Escrow will transfer the bridged amount of tokens, plus the fee, to MM's L2 
address.

Currently, we have 2 implementations of this contract, for 2 different Ethereum ZK L2 Rollups:
- For [Starknet](https://www.starknet.io/en) we have [escrow.cairo](../../../contracts/starknet/src/escrow.cairo), with [its own readme](./Starknet.md)
- For [ZKSync](https://zksync.io/) we have [escrow.sol](../../../contracts/zksync/contracts/escrow.sol), with [its own readme](./ZKSync.md)
