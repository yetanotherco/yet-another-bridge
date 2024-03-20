# Payment Registry

[Payment Registry](../../contracts/solidity/src/PaymentRegistry.sol) is a Smart 
Contract that resides in Ethereum's L1, responsible for receiving MM's transaction 
on L1, forwarding it to the User's address, and sending the information of this 
transaction to Escrow.

So, when MM wants to complete an order it has read on Escrow, it will call the 
`transfer` function from Payment Registry, containing the relevant information 
(orderID, User's address on L1, and amount). Payment Registry will verify the information 
is acceptable, store it, and send the desired amount to User's L1 address.

After this transfer is completed, MM must call `claimPayment` on Payment Registry to 
receive back the initial deposit made by the User, so that Payment Registry can verify 
MM has previously sent the order's amount to the User. If it has, this same function will 
call Escrow's `claim_payment`, informing Escrow that MM has indeed bridged funds for User, 
and that he wants to receive back his amount on L2. Then, as mentioned before, Escrow will 
release MM's funds to his desired L2 address.
