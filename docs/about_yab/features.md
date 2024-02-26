# Features

## Cost Effective

The cost of YAB is similar to an ERC20 transfer plus
the cost of proving the state of the L1 and L2.

Batch transfers and state proofs of the L1 and L2 are currently in the roadmap.

## Performance

From the user's perspective, the bridging from Starknet to Ethereum is completed in less than 30 seconds, or as long as
it takes the market maker to observe the user's deposit and execute a transfer.

From the market maker's perspective, they will be able to withdraw
the money after paying the user and generating the storage proof.

## Reduced Risks

Since the capital is locked for a short period of time (i.e. until the proof is
generated or the message arrives), the risks are minimized and the
attack surface is smaller for the market maker.

## Decentralized Liquidity

The final design handles multiple market makers, so if one market maker
is compromised, the orders can be routed to another market maker instead.
