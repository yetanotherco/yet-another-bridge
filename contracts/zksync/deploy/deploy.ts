import { deployContractWithProxy } from "./utils";
import { deployContract } from "./utils";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import * as dotenv from 'dotenv';
import { utils } from "zksync-ethers";


// It will deploy a Escrow contract to selected network 
export default async function () {
  const escrowArtifactName = "Escrow";
  const escrowConstructorArguments = [];
  const escrow = await deployContract(escrowArtifactName, escrowConstructorArguments);
  // const escrow = await deployContractWithProxy(escrowArtifactName, escrowConstructorArguments);

  dotenv.config();
  
  const ethereum_payment_registry = process.env.PAYMENT_REGISTRY_PROXY_ADDRESS;
  const mm_zksync_wallet = process.env.MM_ZKSYNC_WALLET;

  if (!ethereum_payment_registry || !mm_zksync_wallet) {
    throw new Error("Missing required environment variables.");
  }

  const PaymentRegistryL2Alias = utils.applyL1ToL2Alias(ethereum_payment_registry)

  const initResult = await escrow.initialize(PaymentRegistryL2Alias, mm_zksync_wallet);
  
  // console.log("Initialization result:", initResult);
}
