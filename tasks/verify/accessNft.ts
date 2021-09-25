import hre from "hardhat";
import addresses from "../../utils/addresses/accesspacks.json";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { protocolControl, accessNft, forwarder } = addresses[networkName as keyof typeof addresses];
const contractURI: string = "";

async function AccessNFT() {
  await hre.run("verify:verify", {
    address: accessNft,
    constructorArguments: [protocolControl, forwarder, contractURI],
  });
}

async function verify() {
  await AccessNFT();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });