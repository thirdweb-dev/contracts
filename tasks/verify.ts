import hre from 'hardhat'
import { chainlinkVarsMumbai } from "..//utils/chainlink";
import { controlCenterObj, packObj, marketObj, rngObj, rewardsObj } from "../utils/contracts";

async function ProtocolControl() {
  await hre.run("verify:verify", {
    address: controlCenterObj.address,
    constructorArguments: [
      "0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372" // Deployer address
    ]
  });
}

async function Pack() {
  await hre.run("verify:verify", {
    address: packObj.address,
    constructorArguments: [
        controlCenterObj.address, // Control center adddress
      "$PACK Protocol", // global URI
    ],
  });
}

async function Market() {
  await hre.run("verify:verify", {
    address: marketObj.address, 
    constructorArguments: [
        controlCenterObj.address, // Control center adddress
    ],
  });
}

async function RNG() {
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMumbai;

  await hre.run("verify:verify", {
    address: rngObj.address,
    constructorArguments: [
      controlCenterObj.address, // Control center adddress
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
    ],
  });
}

async function Rewards() {
  await hre.run("verify:verify", {
    address: rewardsObj.address,
    constructorArguments: [],
  });
}

async function verify() {
  await ProtocolControl()
  await Pack()
  await Market()
  await RNG()
  await Rewards()
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
