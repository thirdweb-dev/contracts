import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/addresses/accesspacks.json";
import { txOptions } from "../../utils/txOptions";

import * as fs from "fs";
import * as path from "path";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer
  const [deployer] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  // Get chain specific values
  const txOption = txOptions[networkName as keyof typeof txOptions];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Deploy forwarder.sol
  const forwarder_factory: ContractFactory = await ethers.getContractFactory("Forwarder");
  const forwarder: Contract = await forwarder_factory.deploy(txOption);

  console.log("Deployed Forwarder at: ", forwarder.address);

  await forwarder.deployTransaction.wait();

  // Update contract addresses in `/utils`
  const currentNetworkAddresses = addresses[networkName as keyof typeof addresses];

  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...currentNetworkAddresses,

      forwarder: forwarder.address,
    },
  };

  fs.writeFileSync(path.join(__dirname, "../../utils/address.json"), JSON.stringify(updatedAddresses));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });