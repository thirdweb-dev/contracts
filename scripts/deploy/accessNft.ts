import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/addresses/accesspacks.json";
import ModuleType from "../../utils/protocolModules";
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
  const curentNetworkAddreses = addresses[networkName as keyof typeof addresses];
  const { protocolControl: protocolControlAddress, forwarder: forwarderAddr } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Deploy `NFT`
  const contractURI: string = "";

  const AccessNFT_Factory: ContractFactory = await ethers.getContractFactory("AccessNFT");
  const accessNft = await AccessNFT_Factory.connect(deployer).deploy(
    protocolControlAddress,
    forwarderAddr,
    contractURI,
    txOption,
  );

  console.log(`Deploying Nft: ${accessNft.address} at tx hash: ${accessNft.deployTransaction.hash}`);

  await accessNft.deployed();

  // Get deployed `Nft`'s address
  const nftAddress = accessNft.address;

  // Get `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt("ProtocolControl", protocolControlAddress);

  // Add Module
  const addModuleTx = await protocolControl.addModule(nftAddress, ModuleType.AccessNFT);
  await addModuleTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      accessNft: nftAddress,
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