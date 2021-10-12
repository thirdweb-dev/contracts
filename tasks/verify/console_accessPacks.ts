import hre, { ethers } from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import addresses from "../../utils/addresses/console_ap.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const networkName: string = hre.network.name.toLowerCase();

// Get network dependent vars.
const { protocolControl, pack, market, accessNft, forwarder, registry } = addresses[
  networkName as keyof typeof addresses
] as any;
const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];
const contractURI: string = "";

async function Forwarder() {
  await hre.run("verify:verify", {
    address: forwarder,
    constructorArguments: [],
  });
}

async function Registry() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  await hre.run("verify:verify", {
    address: registry,
    constructorArguments: [deployer.address, forwarder, ethers.constants.AddressZero],
  });
}

async function ProtocolControl() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  await hre.run("verify:verify", {
    address: protocolControl,
    constructorArguments: [registry, deployer.address, contractURI],
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
  //await Forwarder();
  //await Registry();
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
