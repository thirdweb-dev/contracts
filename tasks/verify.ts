import hre from 'hardhat'
import { chainlinkVarsMumbai } from "..//utils/chainlink";
import { controlCenterObj, packObj, marketObj, rewardsObj } from "../utils/contracts";

async function ProtocolControl() {
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMumbai;

  await hre.run("verify:verify", {
    address: controlCenterObj.address,
    constructorArguments: [
      "$PACK Protocol", // global URI
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
    ]
  });
}

async function Pack() {
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMumbai;

  await hre.run("verify:verify", {
    address: packObj.address,
    constructorArguments: [
      controlCenterObj.address, // Control center adddress
      "$PACK Protocol", // global URI
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
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

// async function Rewards() {
//   await hre.run("verify:verify", {
//     address: rewardsObj.address,
//     constructorArguments: [],
//   });
// }

async function verify() {
  await ProtocolControl()
  await Pack()
  await Market()
  // await Rewards()
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
