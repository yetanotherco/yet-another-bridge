### Pause Escrow Contract

Escrow also implements the interesting `Pauseable` module. This means the smart contract 
can be paused and unpaused by the smart contract Owner. When paused, all modifying 
functions are unavailable for everyone, including the Owner.

For this, the Owner must execute the `pause` or `unpause` function from the smart 
contract, you can execute the following:

```bash
make starknet-pause
```

```bash
make starknet-unpause
```

Alternatively, you can directly execute the function using the starkli tool. Note 
however, to run starkli this way, you must have exported the STARKNET_ACCOUNT and 
STARKNET_KEYSTORE variables:

```bash
starkli invoke $ESCROW_CONTRACT_ADDRESS pause
```

```bash
starkli invoke $ESCROW_CONTRACT_ADDRESS unpause 
```

You can also see if the contract is paused or unpaused by executing the following:

```bash
starkli call $ESCROW_CONTRACT_ADDRESS is_paused 
```
