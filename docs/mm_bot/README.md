# Market Maker Bot

Market Maker Bot is a bot that provides liquidity to the Yet Another 
Bridge (YAB).

When a user wants to bridge tokens, the user calls to `set_order` function in Escrow contract.
If it is successful, the Escrow emits a `SetOrder` event with the order information.

The Market Maker Bot listens to the `SetOrder` events and creates a new order in its database.
So, the Market Maker Bot is able to fulfill the user's order.

Once the order is fulfilled, the user has received the tokens in the destination chain. Then,
MM can claim the tokens in the source chain.

When the MM claims the tokens, the Escrow sends the tokens to the MM's address and emits an event
`ClaimPayment`. The order is marked as completed in the MM's database.

## Architecture
In the [Architecture](architecture.md) section you can find the following information:
- Functional Requirements
- Class Diagrams
- Non-Functional Requirements
- Main Architecture Components
- Infrastructure
- Scenarios

## Deploy
If you want to deploy a MM Bot, the [Deploy](deploy.md) section explains how to do it.
