# Declare and Deploy Contracts in Testnet

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

Another starknet dependency used in this project:

- [OpenZeppelin cairo contracts](https://github.com/OpenZeppelin/cairo-contracts/)

## Deploy Payment Registry (on Ethereum)

First, the Ethereum smart contract must be deployed. For Ethereum the deployment process 
you will need to:

1. Create your `.env` file: you need to configure the following variables in your own 
.env file on the contracts/ethereum/ folder. You can use the env.example file as a 
template for creating your .env file, paying special attention to the formats provided

   ```bash
   ETH_RPC_URL = Infura or Alchemy RPC URL

   ETH_PRIVATE_KEY = private key of your ETH wallet

   ETHERSCAN_API_KEY = API Key to use etherscan to read the Ethereum blockchain

   SN_MESSAGING_ADDRESS = Starknet Messaging address
   
   MM_ETHEREUM_WALLET = Ethereum wallet address of the MarketMaker
   ```

   **NOTE**:

   - You can generate ETHERSCAN_API_KEY [following these steps](https://docs.etherscan.io/getting-started/creating-an-account).
   - For the deployment, you will need some ETH.
     - You can get some GoerliEth from this [faucet](https://goerlifaucet.com/).
   - SN_MESSAGING_ADDRESS is for when a L1 contract initiates a message to a L2 contract 
   on Starknet. It does so by calling the sendMessageToL2 function on the Starknet Core 
   Contract with the message parameters. Starknet Core Contracts are the following:
      - Goerli: `0xde29d060D45901Fb19ED6C6e959EB22d8626708e`
      - Sepolia: `0xE2Bb56ee936fd6433DC0F6e7e3b8365C906AA057`
      - Mainnet: `0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4`

2. Deploy Ethereum contract

   ```bash
      make ethereum-deploy
   ```

This will deploy a [ERC1967 Proxy](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ERC1967Proxy) smart contract, a [Payment Registry](ethereum/src/PaymentRegistry.sol) smart 
contract, and it will link them both. The purpose of having a proxy in front of our 
smart contract is so that it is [upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable), by simply deploying another smart 
contract and changing the address pointed by the Proxy.

## Deploy Escrow (on Starknet)

After the Ethereum smart contract is deployed, the Starknet smart contracts must be 
declared and deployed.

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the
  network
- Deploying a contract or creating an instance of the previously declared code
  with the necessary parameters

For this, you will need to:

1. Create your `.env` file: you need to configure the following variables in your own 
.env file on the contracts/ethereum folder. You can use the env.example file as a 
template for creating your .env file, paying special attention to the formats provided

   ```env
   STARKNET_ACCOUNT = Absolute path of your starknet testnet account

   STARKNET_KEYSTORE = Absolute path of your starknet testnet keystore

   SN_RPC_URL = Infura or Alchemy RPC URL

   SN_ESCROW_OWNER = Public address of the owner of the Escrow contract

   MM_SN_WALLET_ADDR = Starknet wallet of the MarketMaker

   CLAIM_PAYMENT_NAME = Exact name of the claim_payment function that is called from L1, case sensitive. 
   Example: claim_payment

   MM_ETHEREUM_WALLET = Ethereum wallet of the MarketMaker

   NATIVE_TOKEN_ETH_STARKNET = Ethereum's erc20 token handler contract in Starknet
   ```

   **Note**
   - For how to create Starknet ACCOUNT and KEYSTORE, you can follow [this tutorial](starknet_wallet_setup.md)
   - SN_ESCROW_OWNER is the only one who can perform upgrades, pause and unpause the 
   smart contract. If not defined, this value will be set (by deploy.sh) to the current 
   deployer of the smart contract.

2. Declare and Deploy: We sequentially declare and deploy the contracts, and connect it 
to our Ethereum smart contract.

### First alternative: automatic deploy and connect of Escrow and Payment Registry

   ```bash
      make starknet-deploy-and-connect
   ```

   This make target consists of 4 steps:

   1. make starknet-build; builds the project
   2. make starknet-deploy; deploys the smart contract on the blockchain
   3. make ethereum-set-escrow; sets the newly created Starknet contract address on the 
Ethereum smart contract, so that the L1 contract can communicate with the L2 contract
   4. make ethereum-set-claim-payment-selector; sets the Starknet _claim_payment_ function name on 
the Ethereum smart contract, so that the L1 contract can communicate with the L2 contract

### Second alternative: manual deploy and connect of Escrow and Payment Registry

This may be better suited for you if you plan to change some of the automatically 
declared variables, or if you simply want to make sure you understand the process.

1. Declare and Deploy
    
    We sequentially declare and deploy the contracts.

   ```bash
    make starknet-deploy
   ```

   This script also defines an important variable, **ESCROW_CONTRACT_ADDRESS**

2. Setting _EscrowAddress_

   After the Starknet smart contracts are declared and deployed, the variable 
_EscrowAddress_ from the Ethereum smart contract must be updated with the newly created 
Starknet smart contract address.

   To do this, you can use

   ```bash
    make ethereum-set-escrow
   ```

   This script uses the previously set variable, **ESCROW_CONTRACT_ADDRESS**

3. Setting _EscrowClaimPaymentSelector_

   Ethereum's smart contract has another variable that must be configured, 
_EscrowClaimPaymentSelector_, which is for specifying the _claim_payment_ function's name in the 
Starknet Escrow smart contract.

   You can set and change Ethereum's _EscrowClaimPaymentSelector_ variable, doing the following:

   ```bash
    make ethereum-set-claim-payment-selector
   ```

   This script uses the CLAIM_PAYMENT_NAME .env variable to automatically generate the 
selector in the necessary format

## Recap

At this point, we should have deployed an ETH smart contract as well as declared and 
deployed a Starknet smart contract, both connected to act as a bridge between these 
two chains.

## Upgrade Contracts in Testnet

### Upgrading Payment Registry (on Ethereum)

After deploying the `Payment Registry` contract, you can perform [upgrades](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) to it. As 
mentioned previously, this is done via a [ERC1967 Proxy](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ERC1967Proxy). So, to upgrade 
Payment Registry, another smart contract must be deployed, and the address stored inside 
the Proxy must be changed.

To do this you must:

1. Configure the `contracts/ethereum/.env` file.

   ```env
      ETH_RPC_URL = Infura or Alchemy RPC URL

      ETH_PRIVATE_KEY = private key of your ETH wallet

      ETHERSCAN_API_KEY = API Key to use etherscan to read the Ethereum blockchain

      SN_MESSAGING_ADDRESS = Starknet Messaging address
   ```

   **NOTE:** This is a very similar configuration than the mentioned before, but 
MM_ETHEREUM_WALLET is not necessary

2. Configure the address of the proxy to be upgraded:

   ```b
      export PAYMENT_REGISTRY_PROXY_ADDRESS = Address of your Payment Registry's Proxy
   ```

3. Use the Makefile command to upgrade `Payment Registry` contract

   ```bash
      make ethereum-upgrade
   ```

   **Note**
   - You must be the **owner** of the contract to upgrade it.
   - This command will:
      - Rebuild `Payment Registry.sol`
      - Deploy the new contract to the network
      - Utilize Foundry to upgrade the previous contract, changing the proxy's pointing 
     address to the newly deployed contract

### Upgrade Escrow (on Starknet)

Our Escrow contract is also upgradeable, but it's method and process of upgrading is 
different from Payment Registry's upgrade. Starknet implemented the `replace_class` syscall, 
allowing a contract to update its source code by replacing its class hash once deployed. 
So, to upgrade Escrow, a new class hash must be declared, and the contract's class 
hash must be replaced.

We will perform the upgrade using the `starkli` tool, so the same configuration used 
for deployment is necessary:

1. Configure `contracts/starknet/.env` file.

   ```env
      STARKNET_ACCOUNT = Path of your starknet account

      STARKNET_KEYSTORE = Path of your starknet keystore
   ```

2. Configure the address of the contract to be upgraded:

   ```bash
      export ESCROW_CONTRACT_ADDRESS = Address of your Escrow smart contract
   ```

3. Use the Makefile command to upgrade `Escrow` contract

   ```bash
      make starknet-upgrade
   ```

   **Note**

- You must be the **owner** of the contract to upgrade it.
- This command will:
  - **rebuild** `Escrow.cairo`
  - **declare** it on Starknet
  - Call the external **upgrade()** function, 
  from [OpenZeppellin's Upgradeable implementation](https://github.com/OpenZeppelin/cairo-contracts/blob/release-v0.8.0/src/upgrades/upgradeable.cairo), with the new class hash

### Pausable

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
