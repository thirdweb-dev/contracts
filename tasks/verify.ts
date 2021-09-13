import hre from "hardhat";
import { chainlinkVars } from "..//utils/chainlink";
import { addresses } from "../utils/contracts";

/// NOTE: set the right address you want
const { controlCenter, pack, market, rewards } = addresses.rinkeby;

async function ProtocolControl() {
  await hre.run("verify:verify", {
    address: controlCenter,
    constructorArguments: [],
  });
}

async function Pack() {
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars.rinkeby;

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
