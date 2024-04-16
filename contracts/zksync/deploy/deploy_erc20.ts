import { deployContractWithProxy } from "./utils";
import { deployContract } from "./utils";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import * as dotenv from 'dotenv';
import { utils } from "zksync-ethers";


// It will deploy a Escrow contract to selected network 
export default async function () {
  const escrowArtifactName = "UriCoin";

  const escrowConstructorArguments = [];
  const escrow = await deployContract(escrowArtifactName, escrowConstructorArguments);
  
  console.log("Deploy erc20 result:", escrow);
}
