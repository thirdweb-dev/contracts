import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/address.json";
import { getTxOptions } from "../../utils/txOptions";

import * as fs from "fs";
import * as path from "path";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer and chainId
  const [deployer] = await ethers.getSigners();
  const chainId: number = await deployer.getChainId();
  const txOption = await getTxOptions(chainId);

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to chain: ${chainId}`);

  // Deploy MinimalForwarder.sol
  const minimalForwarder_factory: ContractFactory = await ethers.getContractFactory("MinimalForwarder");
  const minimalForwarder: Contract = await minimalForwarder_factory.deploy(txOption);

  console.log("Deployed MinimalForwarder at: ", minimalForwarder.address);

  await minimalForwarder.deployTransaction.wait();

  // Update contract addresses in `/utils`
  const networkName: string = hre.network.name.toLowerCase();
  const prevNetworkAddresses = addresses[networkName as keyof typeof addresses];

  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...prevNetworkAddresses,

      forwarder: minimalForwarder.address,
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
