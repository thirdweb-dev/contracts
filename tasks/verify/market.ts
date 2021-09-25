import hre from "hardhat";
import addresses from "../../utils/addresses/accesspacks.json";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { protocolControl, market, forwarder } = addresses[networkName as keyof typeof addresses];
const contractURI: string = "";

async function Market() {
  await hre.run("verify:verify", {
    address: market,
    constructorArguments: [protocolControl, forwarder, contractURI],
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
