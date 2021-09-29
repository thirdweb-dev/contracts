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
  const currentNetworkAddresses = addresses[networkName as keyof typeof addresses];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Deploy `ProtocolControl`
  const protocolControlURI: string = "";
  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const protocolControl: Contract = await ProtocolControl_Factory.deploy(
    deployer.address,
    deployer.address,
    protocolControlURI,
    txOption,
  );

  console.log(
    `Deploying ProtocolControl: ${protocolControl.address} at tx hash: ${protocolControl.deployTransaction.hash}`,
  );

  await protocolControl.deployed();

  // Get Protocol control address.
  const protocolControlAddr: string = protocolControl.address;

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...currentNetworkAddresses,

      protocolControl: protocolControlAddr,
    },
  };

  fs.writeFileSync(path.join(__dirname, "../../utils/addresses/accesspacks.json"), JSON.stringify(updatedAddresses));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
