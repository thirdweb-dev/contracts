import hre, { ethers } from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import addresses from "../../utils/addresses/console.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const networkName: string = hre.network.name.toLowerCase();

// Get network dependent vars.
const { controlDeployer, forwarder, registry, treasury } = addresses[networkName as keyof typeof addresses] as any;

async function verify() {
  await hre.run("verify:verify", {
    address: controlDeployer,
    constructorArguments: [],
  });

  await hre.run("verify:verify", {
    address: forwarder,
    constructorArguments: [],
  });

  await hre.run("verify:verify", {
    address: registry,
    constructorArguments: [treasury, forwarder, controlDeployer],
  });
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
