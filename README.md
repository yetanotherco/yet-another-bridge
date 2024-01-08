# yet-another-bridge

Yet Another Bridge is the cheapest, fastest and most secure bridge solution from Starknet to Ethereum

## Install dependencies

Run the following command:

```bash
make deps
```

This will end up installing:

- [Scarb](https://docs.swmansion.com/scarb) (Cairo/Starknet packet manager) -
  Includes a specific version of the Cairo compiler.
- [Starkli](https://github.com/xJonathanLEI/starkli) - Starkli is a command line tool for interacting with Starknet.
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) - Is a toolchain for developing Starknet smart contracts.
- [Ethereum Foundry](https://book.getfoundry.sh/) - Is a toolchain for developing Ethereum smart contracts.

## Setting up a Starknet Testnet Wallet

**This guide will help you declare and deploy contracts on a testnet. Please
note that you won't be able to use the commands in the Makefile unless you
follow these instructions.**

A smart wallet consists of two parts: a Signer and an Account Descriptor. The
Signer is a smart contract capable of signing transactions (for which we need
its private key). The Account Descriptor is a JSON file containing information
about the smart wallet, such as its address and public key.

Follow the steps below to set up a testnet smart wallet using `starkli`:

1. **Connect to a Provider**: to interact with the network you need an RPC
   Provider. For our project we will be using Alchemy's free tier in Goerli
   Testnet.

   1. Go to [Alchemy website](https://www.alchemy.com/) and create an account.
   2. It will ask which network you want to develop on and choose Starknet.
   3. Select the Free version of the service (we will only need access to send
      some transactions to deploy the contracts)
   4. Once the account creation process is done, go to _My apps_ and create a
      new Application. Choose Starknet as a Chain and Goerli Starknet as a
      Network.
   5. Click on _View key_ on the new Starknet Application and copy the HTTPS
      url.
   6. On your terminal run:

      ```bash
      export STARKNET_RPC="<ALCHEMY_API_HTTPS_URL>"
      ```
2. **Create a Keystore**: A Keystore is a encrypted `json` file that stores the
   private keys.

   1. **Create a hidden folder**: Use the following command:

      ```bash
      mkdir -p ~/.starkli-wallets
      ```
   2. **Generate a new Keystore file**: Run the following command to create a
      new private key stored in the file. It will **ask for a password** to
      encrypt the file:

      ```bash
      starkli signer keystore new ~/.starkli-wallets/keystore.json
      ```

      The command will return the Public Key of your account, copy it to your
      clipboard to fund the account.
   3. **Set STARKNET_ACCOUNT**: To set the environment variable just run:

      ```bash
      export STARKNET_KEYSTORE="~/.starkli-wallets/keystore.json"
      ```
3. **Account Creation**: In Starknet every account is a smart contract, so to
   create one it will need to be deployed.

   1. **Initiate the account with the Open Zeppelin Account contract**:

      ```bash
      starkli account oz init --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
      ```
   2. **Deploy the account by running**:

      ```bash
      starkli account deploy --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
      ```

      For the deployment `starkli` will ask you to fund an account. To do so
      you will need to fund the address given by `starkli` with the
      [Goerli Starknet Faucet](https://faucet.goerli.starknet.io)
4. **Setting Up Environment Variables**: There are two primary environment
   variables vital for effective usage of Starkli’s CLI. These are the location
   of the keystore file for the Signer, and the location of the Account
   Descriptor file:

   ```bash
   export STARKNET_ACCOUNT=~/.starkli-wallets/account.json
   export STARKNET_KEYSTORE=~/.starkli-wallets/keystore.json
   ```

## Declare and Deploy Contracts in Testnet

### Ethereum smart contract
First, the Ethereum smart contracts must be deployed. For Ethereum the deployment process you will need to:

1. Create your `.env` file: you need to configure the following variables in your own .env file on the contracts/solidity/ folder. You can use the env.example file as a template for creating your .env file, paying special attention to the formats provided

   ```bash
   ETH_RPC_URL = Infura or Alchemy RPC URL
   ETH_PRIVATE_KEY = private key of your ETH wallet
   ETHERSCAN_API_KEY = API Key to use etherscan to read the Ethereum blockchain
   ```
   **NOTE**:

   - You can generate ETHERSCAN_API_KEY [following this steps](https://docs.etherscan.io/getting-started/viewing-api-usage-statistics).
   - For the deploy, you will need some GoerliETH that you can get from this [faucet](https://goerlifaucet.com/).


2. Deploy Solidity contract

   ```bash
      make ethereum-deploy
   ```

### Starknet smart contracts

After the Ethereum smart contract is deployed, the Starknet smart contracts must be declared and deployed.
On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the
  network
- Deploying a contract or creating an instance of the previously declared code
  with the necessary parameters

For this, you will need to:

1. Create your `.env` file: you need to configure the following variables in your own .env file on the contracts/solidity folder. You can use the env.example file as a template for creating your .env file, paying special attention to the formats provided

   ```bash
   STARKNET_ACCOUNT = location of your starknet testnet account, created at the start of this README
   STARKNET_KEYSTORE = location of your starknet testnet keystore, created at the start of this README
   SN_RPC_URL = Infura or Alchemy RPC URL
   ETH_CONTRACT_ADDR = newly created ETH contract address
   MM_SN_WALLET_ADDR = Starknet wallet of the MarketMaker

   ```

2. Declare and Deploy: We sequentially declare and deploy the contracts.

   ```bash
      make starknet-deploy
   ```

### Finalize connection between both chains

After the Starknet smart contracts are declared and deployed, one variable from the Ethereum smart contract must be updated with the newly created Starknet smart contract address.

For now, to do this you must go to the ETH explorer and find your ETH smart contract, for example:
https://goerli.etherscan.io/address/0x8C78111CCDd368345c7d6A7bb6A7c887b1093f7A#writeContract
Then, under the "contract/Write Contract" section, you must run the function, with your newly created Starknet escrow contract address as the parameter
```
snEscrowAddress(uint256)
```

This manual solution is temporary and wil be done automatically in the cairo deploy script.

To do this, you can also use Foundry's **cast** function, as follows:

```
cast send \
--rpc-url <eth_rpc_url> \
--private-key <your_private_key> \
<eth_smart_contract_address> "setEscrowAddress(uint256)" <your_new_SN_contract_address>
```

This will send a transaction, using the specified rpc, from the specified address, to the specified smart contract, calling the "setEscrowAddress" function, with your new SN contract address. 



## Recap
After following this complete README, we should have an ETH smart contract as well as a Starknet smart contract, both connected to act as a bridge between these two chains.
