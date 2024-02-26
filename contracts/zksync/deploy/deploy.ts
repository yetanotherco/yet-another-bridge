import { deployContractWithProxy } from "./utils";
import { deployContract } from "./utils";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// It will deploy a Escrow contract to selected network 
// as well as verify it on Block Explorer if possible for the network
export default async function () {
  const escrowArtifactName = "Escrow";
  const escrowConstructorArguments = [];
  // const escrow = await deployContractWithProxy(escrowArtifactName, escrowConstructorArguments);
  const escrow = await deployContract(escrowArtifactName, escrowConstructorArguments);

}
