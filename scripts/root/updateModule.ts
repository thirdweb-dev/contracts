import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory, BytesLike } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";
import { chainlinkVars } from "../../utils/chainlink";

import ProtocolControlABI from "../../abi/ProtocolControl.json";
import RegistryABI from "../../abi/Registry.json";
import PackABI from "../../abi/Pack.json";
import { bytecode } from "../../artifacts/contracts/Pack.sol/Pack.json";

import * as fs from "fs";
import * as path from "path";

/**
 *
 * E.g. scenario -- want to update a module e.g. `Pack` at a given moduleId.
 *
 * To 'delete' a module, update the module to the zero address.
 *
 */

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
  const {
    protocolControl: protocolControlAddress,
    registry: registryAddress,
    pack: prevPackModuleAddress,
  } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Get Forwarder from registry
  const registry: Contract = await ethers.getContractAt(RegistryABI, registryAddress);
  const forwarderAddr: string = await registry.forwarder();

  // Deploy `Pack`
  const Pack_Factory: ContractFactory = new ethers.ContractFactory(PackABI, bytecode);
  const tx = await Pack_Factory.connect(deployer).deploy(
    protocolControlAddress,
    "$PACK Protocol", // This is supposed to be an `ipfs://...` type URI
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarderAddr,
    txOption,
  );

  console.log("Deploying Pack: ", tx.hash);

  await tx.wait();

  // Get deployed `Pack`'s address
  const newPackModuleAddress = tx.address;

  // Get module Id and update `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt(ProtocolControlABI, protocolControlAddress);

  let moduleId: BytesLike = "";
  const allPacks: string[] = await protocolControl.getAllModulesOfType(ModuleType.Pack);

  for (let i = 0; i < allPacks.length; i++) {
    if (prevPackModuleAddress == allPacks[i]) {
      const abiCoder = ethers.utils.defaultAbiCoder;
      moduleId = ethers.utils.keccak256(abiCoder.encode(["uint256", "uint8"], [i, ModuleType.Pack]));
    }
  }

  const updateTx = await protocolControl.updateModule(moduleId, newPackModuleAddress);
  await updateTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      pack: newPackModuleAddress,
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
