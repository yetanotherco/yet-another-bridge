import { deployContractWithProxy } from "./utils";
import { deployContract } from "./utils";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import * as dotenv from 'dotenv';
import { utils } from "zksync-ethers";


// It will deploy a Escrow contract to selected network 
// as well as verify it on Block Explorer if possible for the network
export default async function () {
  const escrowArtifactName = "Escrow";
  const escrowConstructorArguments = [];
  const escrow = await deployContract(escrowArtifactName, escrowConstructorArguments);
  // const escrow = await deployContractWithProxy(escrowArtifactName, escrowConstructorArguments);

  dotenv.config();
  
  const ethereum_payment_registry = process.env.PAYMENT_REGISTRY_PROXY_ADDRESS;
  const mm_ethereum_wallet = process.env.MM_ZKSYNC_WALLET;
  const mm_zksync_wallet = process.env.MM_ZKSYNC_WALLET;
  const native_token_eth_in_zksync = process.env.NATIVE_TOKEN_ETH_IN_ZKSYNC;
  if (!ethereum_payment_registry || !mm_ethereum_wallet || !mm_zksync_wallet || !native_token_eth_in_zksync) {
    throw new Error("Missing required environment variables.");
  }

  const PaymentRegistryL2Alias = utils.applyL1ToL2Alias(ethereum_payment_registry)

  const initResult = await escrow.initialize(PaymentRegistryL2Alias, mm_ethereum_wallet, mm_zksync_wallet, native_token_eth_in_zksync);
  // console.log("Initialization result:", initResult);
}
