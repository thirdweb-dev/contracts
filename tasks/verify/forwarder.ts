import hre from "hardhat";
import addresses from "../../utils/address.json";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { forwarder } = addresses[networkName as keyof typeof addresses];

async function Forwarder() {
  await hre.run("verify:verify", {
    address: forwarder,
    constructorArguments: [],
  });
}

async function verify() {
  await Forwarder();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
