import hre, { ethers } from "hardhat";

// Types
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Utils
import { chainlinkVars } from "../../utils/chainlink";
import addresses from "../../utils/addresses/accesspacks.json";
import ModuleType from "../../utils/protocolModules";

import * as fs from "fs";
import * as path from "path";

async function main(): Promise<void> {
  // Get deployer
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  const networkName: string = hre.network.name;
  const curentNetworkAddreses = addresses[networkName as keyof typeof addresses];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Deploy Forwarder
  const Forwarder_Factory: ContractFactory = await ethers.getContractFactory("Forwarder");
  const forwarder: Contract = await Forwarder_Factory.deploy();

  console.log(`Deploying Forwarder: ${forwarder.address} at tx hash: ${forwarder.deployTransaction.hash}`);

  await forwarder.deployed();

//   // Deploy ProtocolControl

//   const admin = deployer.address;
//   const protocolProvider = deployer.address;
//   const providerTreasury = deployer.address;
//   const protocolControlURI: string = "";

//   const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
//   const protocolControl: Contract = await ProtocolControl_Factory.deploy(
//     admin,
//     protocolProvider,
//     providerTreasury,
//     protocolControlURI,
//   );

//   console.log(
//     `Deploying ProtocolControl: ${protocolControl.address} at tx hash: ${protocolControl.deployTransaction.hash}`,
//   );

//   await protocolControl.deployed();

//   // Deploy Pack
//   const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];
//   const packContractURI: string = "";

//   const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack_PL");
//   const pack: Contract = await Pack_Factory.deploy(
//     protocolControl.address,
//     packContractURI,
//     vrfCoordinator,
//     linkTokenAddress,
//     keyHash,
//     fees,
//     forwarder.address,
//   );

//   console.log(`Deploying Pack: ${pack.address} at tx hash: ${pack.deployTransaction.hash}`);

//   await pack.deployed();

//   const addModuleTxPack = await protocolControl.addModule(pack.address, ModuleType.Pack);
//   await addModuleTxPack.wait();

//   // Deploy Market
//   const marketContractURI: string = "";

//   const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
//   const market: Contract = await Market_Factory.deploy(protocolControl.address, forwarder.address, marketContractURI);

//   console.log(`Deploying Market: ${market.address} at tx hash: ${market.deployTransaction.hash}`);

//   await market.deployed();

//   const addModuleTxMarket = await protocolControl.addModule(market.address, ModuleType.Market);
//   await addModuleTxMarket.wait();

//   // Deploy AccessNFT
//   const accessNFTContractURI: string = "";

//   const AccessNFT_Factory: ContractFactory = await ethers.getContractFactory("AccessNFT_PL");
//   const accessNft: Contract = await AccessNFT_Factory.deploy(
//     protocolControl.address,
//     forwarder.address,
//     accessNFTContractURI,
//   );

//   console.log(`Deploying AccessNFT: ${accessNft.address} at tx hash: ${accessNft.deployTransaction.hash}`);

//   await accessNft.deployed();

//   const addModuleTxAccess = await protocolControl.addModule(accessNft.address, ModuleType.AccessNFT);
//   await addModuleTxAccess.wait();

//   // Update contract addresses in `/utils`
//   const updatedAddresses = {
//     ...addresses,

//     [networkName]: {
//       ...curentNetworkAddreses,

//       protocolControl: protocolControl.address,
//       forwarder: forwarder.address,
//       pack: pack.address,
//       market: market.address,
//       accessNft: accessNft.address,
//     },
//   };

//   fs.writeFileSync(path.join(__dirname, "../../utils/addresses/accesspacks.json"), JSON.stringify(updatedAddresses));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
