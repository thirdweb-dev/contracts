import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory, Bytes } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";

import * as fs from "fs";
import * as path from "path";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer and chainId
  const [deployer] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Get chain specific values
  const currentNetworkAddresses = addresses[networkName as keyof typeof addresses];
  const { protocolControl: protocolControlAddr, forwarder: forwarderAddr } = currentNetworkAddresses;
  const txOption = txOptions[networkName as keyof typeof txOptions];

  // Deploy Market.sol
  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(protocolControlAddr, forwarderAddr, txOption);

  console.log("Market.sol deployed at: ", market.address);

  // Update module in `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt("ProtocolControl", protocolControlAddr);

  const moduleId: Bytes = await protocolControl.MARKET();
  const updateTx = await protocolControl.updateModule(moduleId, market.address, txOption);

  console.log("Updating MARKET module in ProtocolControl: ", updateTx.hash);

  await updateTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...currentNetworkAddresses,

      market: market.address,
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
