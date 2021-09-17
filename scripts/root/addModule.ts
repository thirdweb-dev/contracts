import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";

import ProtocolControlABI from "../../abi/ProtocolControl.json";
import RegistryABI from "../../abi/Registry.json";
import NftABI from "../../abi/NFT.json";
import { bytecode } from "../../artifacts/contracts/Nft.sol/Nft.json";

import * as fs from "fs";
import * as path from "path";

/**
 *
 * E.g. scenario -- want to add an NFT contract to root.
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
  const { protocolControl: protocolControlAddress, registry: registryAddress } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Get Forwarder from registry
  const registry: Contract = await ethers.getContractAt(RegistryABI, registryAddress);
  const forwarderAddr: string = await registry.forwarder();

  // Deploy `NFT`
  const contractURI: string = "ipfs://...";

  const Nft_Factory: ContractFactory = new ethers.ContractFactory(NftABI, bytecode);
  const tx = await Nft_Factory.connect(deployer).deploy(contractURI, protocolControlAddress, forwarderAddr, txOption);

  console.log("Deploying Nft: ", tx.hash);

  await tx.wait();

  // Get deployed `Nft`'s address
  const nftAddress = tx.address;

  // Get `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt(ProtocolControlABI, protocolControlAddress);
  const addModuleTx = await protocolControl.addModule(nftAddress, ModuleType.NFT);
  await addModuleTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      nft: nftAddress,
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
