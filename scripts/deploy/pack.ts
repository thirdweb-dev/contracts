import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";
import { chainlinkVars } from "../../utils/chainlink";

import ProtocolControlABI from "../../abi/ProtocolControl.json";
import RegistryABI from "../../abi/Registry.json";
import PackABI from "../../abi/Pack.json";
import { bytecode } from "../../artifacts/contracts/Pack.sol/Pack.json";

import * as fs from "fs";
import * as path from "path";

enum ModuleType {
  Coin = 0,
  NFTCollection = 1,
  NFT = 2,
  DynamicNFT = 3,
  AccessNFT = 4,
  Pack = 5,
  Market = 6,
  Other = 7,
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
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Get Forwarder from registry
  const registry: Contract = await ethers.getContractAt(RegistryABI, registryAddress);
  const forwarderAddr: string = await registry.forwarder();

  // Deploy `Pack`
  const contractURI: string = "ipfs://QmYMgpVGBgVZunM2uDPnobsHpryMmkXF8ZPJGiHfLpwShS";
  const Pack_Factory: ContractFactory = new ethers.ContractFactory(PackABI, bytecode);
  const tx = await Pack_Factory.connect(deployer).deploy(
    protocolControlAddress,
    contractURI,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarderAddr,
    txOption,
  );

  console.log("Deploying Pack: ", tx.hash, tx.address);
  console.log(
    tx.address,
    protocolControlAddress,
    contractURI,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarderAddr,
  );

  await tx.deployed();

  // Get deployed `Pack`'s address
  const packAddress = tx.address;

  // Get `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt(ProtocolControlABI, protocolControlAddress);
  const addModuleTx = await protocolControl.addModule(packAddress, ModuleType.Pack);
  await addModuleTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      pack: packAddress,
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
