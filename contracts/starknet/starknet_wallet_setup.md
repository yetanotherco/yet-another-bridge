# Setting up a Starknet Testnet Wallet

Accounts on Starknet are not like in Ethereum. Instead, they are a smart contract that act as a wallet for the user (commonly referred as a Smart Wallet).

A smart wallet consists of two parts: a Signer and an Account Descriptor:
- The Signer is a smart contract capable of signing transactions (for which we need
its private key).
- The Account Descriptor is a JSON file containing information
about the smart wallet, such as its address and public key.

## Follow the steps below to set up a smart wallet using `starkli`:

1. **Connect to a Provider**: to interact with the network you need an RPC
   Provider. For our project we will be using Alchemy's free tier in Goerli
   Testnet.

   1. Go to [Alchemy website](https://www.alchemy.com/) and create an account.
   2. It will ask which network you want to develop on and choose Starknet.
   3. Select the Free version of the service (we will only need access to send
      some transactions to deploy the contracts)
   4. Once the account creation process is done, go to _My apps_ and create a
      new Application. Choose Starknet as a Chain and the network you want to use in Starknet.
   5. Click on _View key_ on the new Starknet Application and copy the HTTPS
      url.
   6. On your terminal run:

      ```bash
      export STARKNET_RPC="<ALCHEMY_API_HTTPS_URL>"
      ```

2. **Create a Keystore**: A Keystore is an encrypted `json` file that stores the
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
   3. **Set STARKNET_KEYSTORE**: To set the environment variable just run:

      ```bash
      export STARKNET_KEYSTORE="~/.starkli-wallets/keystore.json"
      ```

3. **Account Creation**: In Starknet every account is a smart contract, so to
   create one it will need to be deployed.

   1. **Initiate the account with the Open Zeppelin Account contract**:

      ```bash
      starkli account <account-variant> init --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
      ```
      The [current version of Starkli](https://book.starkli.rs/accounts) supports these account variants (by alphabetical order):
   
       | Vendor       | Identifier | Link                                            |
       |--------------|------------|-------------------------------------------------|
       | Argent       | argent     | https://www.argent.xyz/argent-x/                |
       | Braavos      | braavos    | https://braavos.app/                            |
       | OpenZeppelin | oz         | https://github.com/OpenZeppelin/cairo-contracts |

   2. **Deploy the account by running**:

      ```bash
      starkli account deploy --keystore ~/.starkli-wallets/keystore.json ~/.starkli-wallets/account.json
      ```

      For the deployment `starkli` will ask you to fund an account. To do so
      you will need to fund the address given by `starkli`.
      - In Goerli you can use [Goerli Starknet Faucet](https://faucet.goerli.starknet.io)
      
4. **Setting Up Environment Variables**: There are two primary environment
   variables vital for effective usage of Starkli’s CLI. These are the location
   of the keystore file for the Signer, and the location of the Account
   Descriptor file:

   ```bash
   export STARKNET_ACCOUNT=~/.starkli-wallets/account.json
   export STARKNET_KEYSTORE=~/.starkli-wallets/keystore.json
   ```
