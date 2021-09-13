import hre from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import addresses from "../../utils/address.json";

const networkName: string = hre.network.name.toLowerCase();

// Get network dependent vars.
const { protocolControl, pack, market, rewards } = addresses[networkName as keyof typeof addresses];
const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];

async function ProtocolControl() {
  await hre.run("verify:verify", {
    address: protocolControl,
    constructorArguments: [],
  });
}

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

async function Market() {
  await hre.run("verify:verify", {
    address: market,
    constructorArguments: [
      protocolControl, // Control center adddress
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
