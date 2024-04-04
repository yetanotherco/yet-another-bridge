# Deploy

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

[comment]: TODO add install ZKSync dockerized L1-L2 or in-memory-node if/when necessary, for make tests 

## Deploy Payment Registry (on Ethereum)

First, the Ethereum Payment Registry must be deployed. For Ethereum the deployment process 
you will need to:

1. Create your `.env` file: you need to configure the following variables in your own 
.env file on the contracts/ethereum/ folder. You can use the env.example file as a 
template for creating your .env file, paying special attention to the formats provided

   ```bash
   ETHEREUM_RPC = RPC provider URL

   ETHEREUM_PRIVATE_KEY = private key of your ETH wallet

   ETHERSCAN_API_KEY = API Key to use etherscan to read the Ethereum blockchain

   MM_ETHEREUM_WALLET_ADDRESS = Ethereum wallet address of the MarketMaker

   STARKNET_MESSAGING_ADDRESS = Starknet Messaging address in L1

   STARKNET_CLAIM_PAYMENT_SELECTOR = hex value of starknet\'s claim_payment selector

   ZKSYNC_DIAMOND_PROXY_ADDRESS = ZKSync Diamond Proxy address in L1

   ZKSYNC_CLAIM_PAYMENT_SELECTOR = hex value of ZKSync's claim_payment selector
   ```

   **NOTE**:

   - You can generate ETHERSCAN_API_KEY [following these steps](https://docs.etherscan.io/getting-started/creating-an-account).
   - For the deployment, you will need some ETH.
     - You can get some SepoliaETH from [Infura](https://www.infura.io/faucet/sepolia) or [Alchemy](https://www.alchemy.com/faucets/ethereum-sepolia).
   - STARKNET_MESSAGING_ADDRESS is for when a L1 contract initiates a message to a L2 contract 
   on Starknet. It does so by calling the sendMessageToL2 function on the Starknet Core 
   Contract with the message parameters. Starknet Core Contracts are the following:
      - Sepolia: `0xE2Bb56ee936fd6433DC0F6e7e3b8365C906AA057`
      - Mainnet: `0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4`
   - ZKSYNC_DIAMOND_PROXY_ADDRESS is for when a L1 contract initiates a message to a L2 contract on ZKSync. It does so by calling the requestL2Transaction function on the ZKSync Core Contract with the message parameters. ZKSync Diamond Proxy's addresses are the following:
      - Sepolia: `0x9A6DE0f62Aa270A8bCB1e2610078650D539B1Ef9`
      - Mainnet: `0x32400084C286CF3E17e7B677ea9583e60a000324`
   - You can generate the STARKNET_CLAIM_PAYMENT_SELECTOR value with `starkli`, by running, for example:
   ```bash
   stakli selector claim_payment
   ```

   - You can generate the ZKSYNC_CLAIM_PAYMENT_SELECTOR value by using `cast sig`, by running, for example:
   ```bash
   cast sig "claim_payment(uint256 order_id, address recipient_address, uint256 amount)"
   ```

2. Deploy Ethereum contract

   ```bash
      make ethereum-deploy
   ```

This will deploy a [ERC1967 Proxy](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ERC1967Proxy) smart contract, a [Payment Registry](../../contracts/ethereum/src/PaymentRegistry.sol) smart 
contract, and it will link them both. The purpose of having a proxy in front of our 
Payment Registry is so that it is [upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable), by simply deploying another smart 
contract and changing the address pointed by the Proxy.

## Deploy Escrow (on Starknet)

After the Ethereum Payment Registry is deployed, the Starknet Escrow must be 
declared and deployed.

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the
  network
- Deploying a contract or creating an instance of the previously declared code
  with the necessary parameters

For this, you will need to:

1. Create your `.env` file: you need to configure the following variables in your own 
.env file on the contracts/starknet folder. You can use the env.example file as a 
template for creating your .env file, paying special attention to the formats provided

   ```bash
   STARKNET_ACCOUNT = Absolute path of your starknet testnet account

   STARKNET_KEYSTORE = Absolute path of your starknet testnet keystore

   STARKNET_RPC = Infura or Alchemy RPC URL

   STARKNET_ESCROW_OWNER = Public address of the owner of the Escrow contract

   MM_STARKNET_WALLET_ADDRESS = Starknet wallet of the MarketMaker

   MM_ETHEREUM_WALLET_ADDRESS = Ethereum wallet of the MarketMaker

   NATIVE_TOKEN_ETH_STARKNET = Ethereum's erc20 token handler contract in Starknet
   ```

   **Note**
   - STARKNET_ESCROW_OWNER is the only one who can perform upgrades, pause and unpause the 
   smart contract. If not defined, this value will be set (by deploy.sh) to the current 
   deployer of the smart contract.

2. Declare and Deploy: We sequentially declare and deploy the contracts, and connect it 
to our Ethereum Payment Registry.

### First alternative: automatic deploy and connect of Escrow and Payment Registry

   ```bash
      make starknet-deploy-and-connect
   ```

   This make target consists of 3 steps:

   1. make starknet-build; builds the project
   2. make starknet-deploy; deploys the Escrow on the Starknet blockchain
   3. make ethereum-set-escrow; sets the newly created Starknet contract address on the 
Ethereum Payment Registry, so that the L1 contract can communicate with the L2 contract

### Second alternative: manual deploy and connect of Escrow and Payment Registry

This may be better suited for you if you plan to change some of the automatically 
declared variables, or if you simply want to make sure you understand the process.

<details>
<summary>Steps</summary>
1. Declare and Deploy
    
   We sequentially declare and deploy the contracts. This also builds the project beforehand.

   ```bash
    make starknet-deploy
   ```

   This script also defines an important variable, **ESCROW_CONTRACT_ADDRESS**

2. Setting _EscrowAddress_

   After the Starknet Escrow is declared and deployed, the variable 
_EscrowAddress_ from the Ethereum Payment Registry must be updated with the newly created 
Starknet Escrow address.

   To do this, you can use

   ```bash
    make ethereum-set-escrow
   ```

   This script uses the previously set variable, **ESCROW_CONTRACT_ADDRESS**
</details>


## Deploy Escrow (on ZKSync)

After the Ethereum Payment Registry is deployed, the ZKSync Escrow must be deployed.

For this, you will need to:

1. Create your `.env` file: you need to configure the following variables in your own 
.env file on the contracts/zksync folder. You can use the env.example file as a 
template for creating your .env file, paying special attention to the formats provided

   ```bash
   WALLET_PRIVATE_KEY = Private key of the deployer 

   MM_ZKSYNC_WALLET = Public address of the Market Maker in ZKSync
   ```

2. We deploy the contract, and connect it to our Ethereum Payment Registry.

### First alternative: automatic deploy and connect of Escrow and Payment Registry

   ```bash
      make zksync-deploy-and-connect
   ```

   This make target consists of 3 steps:

   1. make zksync-build; builds the project
   2. make zksync-deploy; deploys the Escrow on the ZKSync blockchain
   3. ./set_zksync_escrow.sh; sets the newly created ZKSync contract address on the 
Ethereum Payment Registry, so that the L1 contract can communicate with the L2 contract

### Second alternative: manual deploy and connect of Escrow and Payment Registry

This may be better suited for you if you plan to change some of the automatically 
declared variables, or if you simply want to make sure you understand the process.

<details>
<summary>Steps</summary>
1. Declare and Deploy
    
   We sequentially declare and deploy the contracts. This also builds the project beforehand.

   ```bash
    make zksync-deploy
   ```

   This script also defines an important variable, **ZKSYNC_ESCROW_CONTRACT_ADDRESS**

2. Setting _ZKSyncEscrowAddress_

   After the ZKSync Escrow is deployed, the variable  _ZKSyncEscrowAddress_ from the Ethereum Payment Registry must be updated with the newly created ZKSync Escrow address, to connect these both smart contracts.

   To do this, you can use

   ```bash
    make zksync-connect
   ```

   This script uses the previously set variable, **ZKSYNC_ESCROW_CONTRACT_ADDRESS**
</details>


## Recap

At this point, we should have deployed an Ethereum smart contract, Payment Registry, as well as declared and deployed 2 L2 Escrows, one on Starknet and another one on ZKSync, both connected to Ethereum Payment Registry to act as a bridge between these chains.

## More deploy targets

There also exists more make targets that can help us deploy more easily and more quickly our smart contracts. Once we have correctly configured out _.env_ files, as explained above, we can use the following make targets:

To deploy only our Ethereum Payment Registry and our Escrow on Starknet:
```bash
make ethereum-and-starknet-deploy
```

To deploy only our Ethereum Payment Registry and our Escrow on ZKSync:
```bash
make ethereum-and-zksync-deploy
```

To deploy everything stated above, our Ethereum Payment Registry, an Escrow on Starknet and another Escrow on ZKSync:
```bash
make deploy-all
```

