import hre, { ethers } from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import addresses from "../../utils/addresses/accesspacks.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const networkName: string = hre.network.name.toLowerCase();

// Get network dependent vars.
const { protocolControl, pack, market, accessNft, forwarder } = addresses[networkName as keyof typeof addresses];
const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];
const contractURI: string = "";

async function ProtocolControl() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  await hre.run("verify:verify", {
    address: protocolControl,
    constructorArguments: [deployer.address, deployer.address, contractURI],
  });
}

async function Pack() {
  await hre.run("verify:verify", {
    address: pack,
    constructorArguments: [protocolControl, contractURI, vrfCoordinator, linkTokenAddress, keyHash, fees, forwarder],
  });
}

async function Market() {
  await hre.run("verify:verify", {
    address: market,
    constructorArguments: [protocolControl, forwarder, contractURI],
  });
}

async function AccessNFT() {
  await hre.run("verify:verify", {
    address: accessNft,
    constructorArguments: [protocolControl, forwarder, contractURI],
  });
}

async function verify() {
  await ProtocolControl();
  await Pack();
  await Market();
  await AccessNFT();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });