# Escrow

[Escrow](../../contracts/cairo/src/escrow.cairo) is a Smart Contract written in Cairo that resides in Ethereum's L2 Starknet.

This contract is responsible for receiving Users' payments in L2, and liberating them 
to the MM when, and only when, the MM has proved the L1 payment.

This contract has a storage of all orders. When a new order is made, by calling the 
`set_order` function, this contract reads the new order's details, verifies the Order 
is acceptable, and if so, it stores this data and accepts from the sender the 
appropriate amount of tokens. An Order's details are: the address where the User wants 
to receive the transaction on L1, the amount he wants to receive, and the amount he is 
willing to give the MM to concrete the bridge process.

Once Escrow has accepted the new order, it will emit a `SetOrder` event, containing 
this information so that MMs can decide if they want to accept this offer.

The user must wait until an MM picks its order, which should be almost instantaneous 
if the transfer fee is the suggested one.

After an MM consolidates an order, Escrow will receive a `claim_payment` call from 
Payment Registry, containing the information about how MM has indeed bridged the funds 
to the User's L1 address, and where does MM wants to receive its L2 tokens. Escrow 
will then cross-check this information to its own records, and if everything is in 
check, Escrow will transfer the bridged amount of tokens, plus the fee, to MM's L2 
address.

