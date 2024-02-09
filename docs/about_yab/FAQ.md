# FAQ

## What is YAB?
Yet Another Bridge (YAB) is the cheapest, fastest and most secure bridge 
solution from Starknet to Ethereum. 

## What makes YAB different from other bridge solutions?
Bridges are generally insecure and economically inefficient. They exhibit an 
asymmetry between users and bridge operators, where users can easily lose funds. 
We propose a bridge design that is simple, modular, and utilizes multi-storage 
proofs and the native messaging system between Ethereum and Layer 2 networks 
(L2s) as a fallback mechanism.

## How much time does it take to bridge?
From the user's perspective, the bridging is completed in less than 30 seconds, 
as quickly as the time it takes the market maker to observe the user's deposit 
and execute a transfer.

From the market maker’s perspective, they will be able to receive back the money 
after paying the user and sending a message using the native messaging system. 
It takes less than 30 seconds, due to the time it takes to make a transaction 
in Ethereum and the L2’s sequencer receiving the message.

Storage proofs are also implemented but they are not in use because they are useful to 
scale and bridge from multiple L2 chains. This normally takes between 5 and 15 
minutes.

## How much does it cost to bridge?
The cost of this bridge is similar to an ERC20 transfer plus the cost of proving the state of the L1 and L2. So, the bridge cost is approximately $15.

## What chains are currently supported?
Currently, Starknet is the only supported chain.

We are working on ZkSync integration.

## How can I get in touch with the team?
You can contact us in
- [Telegram](https://t.me/grindlabs)
- [Twitter](https://twitter.com/yanotherbridge)
