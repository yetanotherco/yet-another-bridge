# Market Maker Bot

Market Maker Bot is a bot that provides liquidity to the Yet Another 
Bridge (YAB).

When a user wants to bridge tokens using YAB, the user must call the `set_order` function from the Escrow contract.
If successful, the Escrow emits a `SetOrder` event with the newly placed order information.

The Market Maker Bot listens to the `SetOrder` events and creates a new order in its database.
This way, the Market Maker Bot is able to fulfill all user's order.

Once an order is fulfuilled, when the user has received the tokens in his desired destination chain,
the Market Maker will be able to claim his corresponding tokens from the Escrow in the source chain.

When the Market Maker claims its tokens, the Escrow will send the tokens to the Market Maker's address and emit a `ClaimPayment` event. 
The order is then marked as completed in the Market Maker's database.

## Architecture
In the [Architecture](architecture.md) section you can find the following information:
- Functional Requirements
- Class Diagrams
- Non-Functional Requirements
- Main Architecture Components
- Infrastructure
- Scenarios

## Deploy
If you want to deploy a Market Maker Bot, the [Deploy](deploy.md) section explains how to do it.
