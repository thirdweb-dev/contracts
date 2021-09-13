import hre from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import { addresses } from "../../utils/contracts";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { controlCenter, pack, market, rewards } = addresses[networkName];
const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName];

async function ProtocolControl() {
  await hre.run("verify:verify", {
    address: controlCenter,
    constructorArguments: [],
  });
}

async function Pack() {
  await hre.run("verify:verify", {
    address: pack,
    constructorArguments: [
      controlCenter, // Control center adddress
      "$PACK Protocol", // global URI
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees,
    ],
  });
}

async function Market() {
  await hre.run("verify:verify", {
    address: market,
    constructorArguments: [
      controlCenter, // Control center adddress
    ],
  });
}

async function Rewards() {
  await hre.run("verify:verify", {
    address: rewards,
    constructorArguments: [pack],
  });
}

async function verify() {
  await ProtocolControl();
  await Pack();
  await Market();
  await Rewards();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
