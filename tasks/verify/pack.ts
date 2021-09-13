import hre from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import addresses from "../../utils/address.json";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { protocolControl, pack } = addresses[networkName as keyof typeof addresses];
const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];

async function Pack() {
  await hre.run("verify:verify", {
    address: pack,
    constructorArguments: [
      protocolControl, // Control center adddress
      "$PACK Protocol", // global URI
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees,
    ],
  });
}

async function verify() {
  await Pack();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
