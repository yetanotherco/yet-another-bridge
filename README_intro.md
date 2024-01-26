# Yet-Another-Bridge

Yet Another Bridge is the cheapest, fastest and most secure bridge solution from Starknet to Ethereum

## Ok, but how does it work?

YAB is conformed primarily by 2 Smart Contracts, one Smart Contract on L1 ETH blockchain (called YABTransfer), and one Smart Contract on L2 Starknet blockchain (called Escrow).

Another vital entity for YAB's functionality is the Market Maker (MM for short) 

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