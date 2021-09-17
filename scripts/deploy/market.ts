import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";

import ProtocolControlABI from "../../abi/ProtocolControl.json";
import RegistryABI from "../../abi/Registry.json";
import MarketABI from "../../abi/Market.json";
import { bytecode } from "../../artifacts/contracts/Market.sol/Market.json";

import * as fs from "fs";
import * as path from "path";

enum ModuleType {
  Coin,
  NFT,
  Pack,
  Market,
  Other,
}

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer
  const [deployer] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  // Get chain specific values
  const curentNetworkAddreses = addresses[networkName as keyof typeof addresses];
  const { protocolControl: protocolControlAddress, registry: registryAddress } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Get Forwarder from registry
  const registry: Contract = await ethers.getContractAt(RegistryABI, registryAddress);
  const forwarderAddr: string = await registry.forwarder();

  // Deploy `Market`
  const Market_Factory: ContractFactory = new ethers.ContractFactory(MarketABI, bytecode);
  const tx = await Market_Factory.connect(deployer).deploy(protocolControlAddress, forwarderAddr, txOption);

  console.log("Deploying Market: ", tx.hash);

  await tx.wait();

  // Get deployed `Market`'s address
  const marketAddress = tx.address;

  // Get `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt(ProtocolControlABI, protocolControlAddress);
  const addModuleTx = await protocolControl.addModule(marketAddress, ModuleType.Market);
  await addModuleTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      market: marketAddress,
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
