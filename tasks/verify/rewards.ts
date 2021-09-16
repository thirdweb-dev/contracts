import hre from "hardhat";
import addresses from "../../utils/address.json";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { pack, rewards, forwarder } = addresses[networkName as keyof typeof addresses];

async function Rewards() {
  await hre.run("verify:verify", {
    address: rewards,
    constructorArguments: [
      pack,
      forwarder
    ],
  });
}

async function verify() {
  await Rewards();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
