# Yet-Another-Bridge

Yet Another Bridge is the cheapest, fastest and most secure bridge solution from Starknet to Ethereum

## Ok, but how does it work?

YAB is conformed primarily by 2 Smart Contracts, one Smart Contract on L1 ETH blockchain (called YABTransfer), and one Smart Contract on L2 Starknet blockchain (called Escrow). Another vital entity for YAB's functionality is the Market Maker (MM for short).

And, of course, the users.

- To the user, the process is as follows:

    1. The user want to bridge L2 ETH tokens from Starknet to L1 Ethereum
    2. The user deposits ETH tokens on L2 Escrow, while also sending some extra information; such as where does the user want to recieve the money on L1, how much fee does he want to give to the Market Maker, etc.
    3. The user recieves in his L1 wallet a transaction of the amount sent to Escrow (minus fees) from a YABTransfer's address

    Done, the User has bridged tokens from L2 to L1, in the time it takes to complete 2 simple transactions.

- For a MM, the process is as follows:

    1. The MM holds his ETH tokens on his own private L1 wallet
    2. The MM monitors Escrow's activity logs and events, to detect any Users wanting to bridge tokens
    3. MM detects a User that has transferred ETH tokens to L2 Escrow, and decides the amount to bridge with the transfer fee is acceptable
    4. When the transaction has been accepted by the blockchain, MM sends the ETH tokens on L1 to YABTransfer, specifying the User's orderID, L1 wallet address, etc.
    5. Then, YABTransfer sends the ETH tokens to the User, and generates a storage proof, proving the User has recieved the appropriate funds, and sends this proof to L2 Escrow
    6. Escrow validates this storage proof, and sends the ETH Tokens (plus fees) to MM's L2 wallet.

    Done, MM has sent ETH to a L1 address, and recieved same ETH plus fees on L2.

The whole process is shown in the following diagram:

![YAB-diagram](YAB-diagram.png)

# This Project

In this repo you will find both Smart Contracts, L1 YABTransfer contract (written in Solidity) and L2 Escrow contract (written in Cairo), and a MM-bot (written in Python).

Each folder has it's corresponding README to deploy and use them correctly, and also some extra information to be able to understand them better.

## YABTransfer

YABTransfer is a Smart Contract written in Solidity that resides in Ethereum's L1.

This contract is 

## Escrow

Escrow is a Smart Contract written in Cairo that resides in Ethereum's L2 Starknet.

This contract is responsable for recieving Users' payments in L2, and liberating them to the MM when, and only when, appropriate.

This contract has a storage of all open (and closed!) orders. When a new order is made, by calling the `set_order` function, this contract reads the new order's details, verifies the Order is acceptable, and if so, it stores this data and accepts from the sendes the appropriate amount of tokens. An Order's details are: the address where the User wants to recieve the transaction on L1, the amount he wants to recieve, and the amount he is willing to give the MM to concrete the bridge process.

Once Escrow has accepted the new order, it will emit a `SetOrder` event, containing this information so that MMs can decide if they want to accept this offer.

Once the new order is placed, the user must wait until a MM picks it's order, which should be almost instantaneous if the transfer fee is the suggested one! If the order is not chosen by any MM for the minimum wait time (which is currently 12 hours), the user may call the `cancel_order` function from the same address who requested the bridge. While doing this, if the correct information is provided to Escrow, it will cancel the order and return the funds to the user.