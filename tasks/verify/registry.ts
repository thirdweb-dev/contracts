import hre, { ethers } from "hardhat";
import addresses from "../../utils/addresses/generalProtocol.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const networkName: string = hre.network.name;

// Get network dependent vars.
const { registry, forwarder } = addresses[networkName as keyof typeof addresses];

async function Registry() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  await hre.run("verify:verify", {
    address: registry,
    constructorArguments: [deployer.address],
  });
}

async function Forwarder() {
  await hre.run("verify:verify", {
    address: forwarder,
    constructorArguments: [],
  });
}

async function verify() {
  await Registry();
  await Forwarder();
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
