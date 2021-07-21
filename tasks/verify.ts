import hre from 'hardhat'
import { chainlinkVarsRinkeby } from "..//utils/chainlink";

async function ProtocolControl() {
  await hre.run("verify:verify", {
    address: "0x278f941f4d167E6f75f7607c6ff12d86a2757568",
    constructorArguments: [
      "0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372" // Deployer address
    ]
  });
}

async function Pack() {
  await hre.run("verify:verify", {
    address: "0xe3c195AeCFefE42c4f5B2332dcd635930cBB494e",
    constructorArguments: [
      "0x278f941f4d167E6f75f7607c6ff12d86a2757568", // Control center adddress
      "$PACK Protocol", // global URI
    ],
  });
}

async function Market() {
  await hre.run("verify:verify", {
    address: "0x3C5dDEd0160d4cef316138F21b7Cb0B0A77bBf50", 
    constructorArguments: [
      "0x278f941f4d167E6f75f7607c6ff12d86a2757568", // Control center adddress
    ],
  });
}

async function RNG() {
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsRinkeby;

  await hre.run("verify:verify", {
    address: "0x6782e28dC7009DeFea4B7506A8c9ecA9Fd927e47",
    constructorArguments: [
      "0x278f941f4d167E6f75f7607c6ff12d86a2757568", // Control center adddress
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
    ],
  });
}

async function Rewards() {
  await hre.run("verify:verify", {
    address: "0xc36BEd3Ae0ff500F2D2E918Df90B4d59DFAE9942",
    constructorArguments: [],
  });
}

async function verify() {
//   await ProtocolControl()
//   await Pack()
  await Market()
//   await RNG()
//   await Rewards()
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
