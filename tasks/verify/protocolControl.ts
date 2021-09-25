import hre, { ethers } from "hardhat";
import addresses from "../../utils/addresses/accesspacks.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const networkName: string = hre.network.name.toLowerCase();

// Get network dependent vars.
const { protocolControl } = addresses[networkName as keyof typeof addresses];
const contractURI: string = "";

async function ProtocolControl() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  await hre.run("verify:verify", {
    address: protocolControl,
    constructorArguments: [deployer.address, deployer.address, contractURI],
  });
}

async function verify() {
  await ProtocolControl();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
