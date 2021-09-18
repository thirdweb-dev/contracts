import hre, { run, ethers } from "hardhat";
import { Contract } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";

import RegistryABI from "../../abi/Registry.json";

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

  // Get Registry
  const { registry: registryAddress } = currentNetworkAddresses as any;
  const registry: Contract = await ethers.getContractAt(RegistryABI, registryAddress);

  // Deploy `ProtocolControl`
  const protocolControlURI: string = "ipfs://...";
  const tx = await registry.connect(deployer).deployProtocol(txOption);

  console.log("Deploying ProtocolControl: ", tx.hash);

  const receipt = await tx.wait();

  // Get Protocol control address.
  const topic = registry.interface.getEventTopic("DeployedProtocol");
  const log = receipt.logs.find((x: any) => x.topics.indexOf(topic) >= 0);
  const deployEvent = registry.interface.parseLog(log);
  const {
    args: { protocolControlAddr, currentVersion },
  } = deployEvent;

  console.log(`ProtocolControl version ${currentVersion} deployed at ${protocolControlAddr}`);

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...currentNetworkAddresses,

      protocolControl: protocolControlAddr,
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
