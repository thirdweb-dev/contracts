import hre, { ethers } from "hardhat";

// Types
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { chainlinkVars } from "../../utils/chainlink";
import consoleAddresses from "../../utils/addresses/console.json";
import apAddresses from "../../utils/addresses/console_ap.json";
import ModuleType from "../../utils/protocolModules";
import * as fs from "fs";
import * as path from "path";

// Utils
async function main(): Promise<void> {
  // Get deployer
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  const networkName: string = hre.network.name;
  const consoleAddress = consoleAddresses[networkName as keyof typeof consoleAddresses];
  const apAddress = apAddresses[networkName as keyof typeof apAddresses];
  const providerTreasury = apAddress.treasury;

  const forwarder = {
    address: (consoleAddress as any)["forwarder"],
  };

  console.log(
    `Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}. Treasury: ${providerTreasury}`,
  );

  const Registry_Factory: ContractFactory = await ethers.getContractFactory("Registry");
  // @ts-ignore
  const registry: Contract = Registry_Factory.attach(consoleAddress.registry);

  const deployPcTx = await registry.deployProtocol("");
  const tx = await deployPcTx.wait();
  const npc = tx.events.find((t: any) => t.event === "NewProtocolControl");
  const protocolControlAddress = npc.args.controlAddress;

  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  // @ts-ignore
  const protocolControl: Contract = ProtocolControl_Factory.attach(protocolControlAddress);

  // Deploy Pack
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];
  const packContractURI: string = "";

  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(
    protocolControl.address,
    packContractURI,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarder.address,
  );

  console.log(`Deploying Pack: ${pack.address} at tx hash: ${pack.deployTransaction.hash}`);

  await pack.deployed();

  const addModuleTxPack = await protocolControl.addModule(pack.address, ModuleType.Pack);
  await addModuleTxPack.wait();

  // Deploy Market
  const marketContractURI: string = "";

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(protocolControl.address, forwarder.address, marketContractURI);

  console.log(`Deploying Market: ${market.address} at tx hash: ${market.deployTransaction.hash}`);

  await market.deployed();

  const addModuleTxMarket = await protocolControl.addModule(market.address, ModuleType.Market);
  await addModuleTxMarket.wait();

  // Deploy AccessNFT
  const accessNFTContractURI: string = "";

  const AccessNFT_Factory: ContractFactory = await ethers.getContractFactory("AccessNFT");
  const accessNft: Contract = await AccessNFT_Factory.deploy(
    protocolControl.address,
    forwarder.address,
    accessNFTContractURI,
  );

  console.log(`Deploying AccessNFT: ${accessNft.address} at tx hash: ${accessNft.deployTransaction.hash}`);

  await accessNft.deployed();

  const addModuleTxAccess = await protocolControl.addModule(accessNft.address, ModuleType.AccessNFT);
  await addModuleTxAccess.wait();

  const updatedAddresses = {
    ...apAddresses,

    [networkName]: {
      ...apAddress,
      registry: registry.address,
      forwarder: forwarder.address,
      protocolControl: protocolControl.address,
      pack: pack.address,
      market: market.address,
      accessNft: accessNft.address,
    },
  };

  fs.writeFileSync(
    path.join(__dirname, "../../utils/addresses/console_ap.json"),
    JSON.stringify(updatedAddresses, null, 2),
  );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
