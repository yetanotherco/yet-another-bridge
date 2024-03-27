# Upgrade

## Upgrading Payment Registry

After deploying the `Payment Registry` contract, you can perform [upgrades](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) to it. As 
mentioned previously, this is done via a [ERC1967 Proxy](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ERC1967Proxy). So, to upgrade 
Payment Registry, another smart contract must be deployed, and the address stored inside 
the Proxy must be changed.

To do this you must:

1. Configure the `contracts/solidity/.env` file.

   ```env
      ETHEREUM_RPC = RPC provider URL

      ETHEREUM_PRIVATE_KEY = private key of your ETH wallet

      ETHERSCAN_API_KEY = API Key to use etherscan to read the Ethereum blockchain

      STARKNET_MESSAGING_ADDRESS = Starknet Messaging address
   ```

   **NOTE:** This is a very similar configuration than the mentioned before, but 
MM_ETHEREUM_WALLET_ADDRESS is not necessary

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

## Upgrade Escrow

Our Escrow contract is also upgradeable, but it's method and process of upgrading is 
different from Payment Registry's upgrade. Starknet implemented the `replace_class` syscall, 
allowing a contract to update its source code by replacing its class hash once deployed. 
So, to upgrade Escrow, a new class hash must be declared, and the contract's class 
hash must be replaced.

We will perform the upgrade using the `starkli` tool, so the same configuration used 
for deployment is necessary:

1. Configure `contracts/cairo/.env` file.

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

## Upgrade ZKSync
[comment]: TODO, add when ZKSync is Upgradeable