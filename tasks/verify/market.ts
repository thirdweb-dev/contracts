import hre from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import addresses from "../../utils/address.json";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { protocolControl, market } = addresses[networkName as keyof typeof addresses];

async function Market() {
  await hre.run("verify:verify", {
    address: market,
    constructorArguments: [
      protocolControl, // Control center adddress
    ],
  });
}

async function verify() {
  await Market();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
