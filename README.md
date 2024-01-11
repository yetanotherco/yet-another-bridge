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
   SN_MESSAGING_ADDRESS = Starknet Messaging address
   ```
   **NOTE**:

   - You can generate ETHERSCAN_API_KEY [following this steps](https://docs.etherscan.io/getting-started/creating-an-account).
   - For the deploy, you will need some GoerliETH that you can get from this [faucet](https://goerlifaucet.com/).
   - Current SN_MESSAGING_ADDRESS values:
   - SN_MESSAGING_ADDRESS is for when a L1 contract initiates a message to a L2 contract on Starknet. It does so by calling the sendMessageToL2 function on the Starknet Core Contract with the message parameters. Starknet Core Contracts are the following:
      - Goerli: `0xde29d060D45901Fb19ED6C6e959EB22d8626708e`
      - Sepolia: `0xE2Bb56ee936fd6433DC0F6e7e3b8365C906AA057` 
      - Mainnet: `0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4`


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
   STARKNET_ACCOUNT = Absolute path of your starknet testnet account, created at the start of this README
   STARKNET_KEYSTORE = Absolute path of your starknet testnet keystore, created at the start of this README
   SN_RPC_URL = Infura or Alchemy RPC URL
   ETH_CONTRACT_ADDR = newly created ETH contract address
   MM_SN_WALLET_ADDR = Starknet wallet of the MarketMaker
   WITHDRAW_NAME = The exact name of the function that withdraws from the starknet smart contract, case sensitive
   HERODOTUS_FACTS_REGISTRY = Herodotus' Facts Registry Smart Contract in Starknet
   MM_ETHEREUM_WALLET = Ethereum wallet of the MArketMaker
   NATIVE_TOKEN_ETH_STARKNET = Ethereum's erc20 token handler contract in Starkent
   ESCROW_CONTRACT_ADDRESS = Address of the Starknet smart contract, this value should be empty, and is automatically updated after deploy.sh is run
   ```

   **Note**
   - Herodotus Facts Registry:
      - Starknet Goerli: `0x01b2111317EB693c3EE46633edd45A4876db14A3a53ACDBf4E5166976d8e869d`
      - Starknet Sepolia: `0x07d3550237ecf2d6ddef9b78e59b38647ee511467fe000ce276f245a006b40bc`
      - Starknet Mainnet: `0x014bf62fadb41d8f899bb5afeeb2da486fcfd8431852def56c5f10e45ae72765`

2. Declare and Deploy: We sequentially declare and deploy the contracts, and connect it to our Ethereum smart contract.

   ```bash
      make starknet-deploy-and-connect
   ```



### Alternative to _make starknet-deploy-and-connect_

1. Declare and Deploy: We sequentially declare and deploy the contracts.

   ```bash
      make starknet-deploy
   ```

   This script also sets an important .env variable, **ESCROW_CONTRACT_ADDRESS**

2. Setting _EscrowAddress_

After the Starknet smart contracts are declared and deployed, the variable _EscrowAddress_ from the Ethereum smart contract must be updated with the newly created Starknet smart contract address.

To do this, you can use
```
make ethereum-set-escrow
```

This script uses the previously set .env variable, **ESCROW_CONTRACT_ADDRESS**

3. Setting _EscrowWithdrawSelector_ 

Ethereum's smart contract has another variable that must be configured, _EscrowWithdrawSelector_, which is for specifying the _withdraw_ function's name in the Starknet Escrow smart contract.
You can set and change Ethereum's _EscrowWithdrawSelector_ variable, doing the following:
```
make ethereum-set-withdraw-selector
```
This script uses the WITHDRAW_NAME .env variable to automatically generate the selector in the necesary format


## Recap
After following this complete README, we should have an ETH smart contract as well as a Starknet smart contract, both connected to act as a bridge between these two chains.
