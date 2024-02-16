import { deployContract } from "./utils";

// It will deploy a Escrow contract to selected network 
// as well as verify it on Block Explorer if possible for the network
export default async function () {
  const contractArtifactName = "Escrow";
  const constructorArguments = [];
  await deployContract(contractArtifactName, constructorArguments);
}
