import { ethers } from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import { ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { AccessNFT } from "../../typechain/AccessNFT";
import { Registry } from "../../typechain/Registry";
import { ControlDeployer } from "../../typechain/ControlDeployer";
import { NFT } from "../../typechain/NFT";
import { Coin } from "../../typechain/Coin";
import { Pack } from "../../typechain/Pack";
import { Market } from "../../typechain/Market";
import { Forwarder } from "../../typechain/Forwarder";
import { ProtocolControl } from "../../typechain/ProtocolControl";
import { Log } from "@ethersproject/abstract-provider";

export type Contracts = {
  registry: Registry;
  forwarder: Forwarder;
  protocolControl: ProtocolControl;
  accessNft: AccessNFT;
  coin: Coin;
  pack: Pack;
  market: Market;
  nft: NFT;
};

export async function getContracts(
  protocolProvider: SignerWithAddress,
  protocolAdmin: SignerWithAddress, 
  networkName: string = "rinkeby"
): Promise<Contracts> {

  // Deploy Forwarder
  const Forwarder_Factory: ContractFactory = await ethers.getContractFactory("Forwarder")
  const forwarder: Forwarder = (await Forwarder_Factory.connect(protocolProvider).deploy()) as Forwarder;

  // Deploy ControlDeployer
  const ControlDeployer_Factory: ContractFactory = await ethers.getContractFactory("ControlDeployer");
  const controlDeployer: ControlDeployer = (await ControlDeployer_Factory.connect(protocolProvider).deploy()) as ControlDeployer;

  // Deploy Registry
  const Registry_Factory: ContractFactory = await ethers.getContractFactory("Registry");
  const registry: Registry = (await Registry_Factory.connect(protocolProvider).deploy(
    protocolProvider.address,
    forwarder.address,
    controlDeployer.address,
  )) as Registry;

  const REGISTRY_ROLE = await controlDeployer.REGISTRY_ROLE();
  await controlDeployer.connect(protocolProvider).grantRole(REGISTRY_ROLE, registry.address);

  // Deploy ProtocolControl via registry.
  const protocolControlURI: string = "";
  const deployReceipt = await registry.connect(protocolAdmin).deployProtocol(protocolControlURI).then(tx => tx.wait());
  const log = deployReceipt.logs.find(x => x.topics.indexOf(registry.interface.getEventTopic("NewProtocolControl")) >= 0);
  const protocolControlAddr: string = registry.interface.parseLog(log as Log).args.controlAddress;
  const protocolControl: ProtocolControl = await ethers.getContractAt("ProtocolControl", protocolControlAddr) as ProtocolControl;

  // Deploy Pack
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];
  const packContractURI: string = "";

  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Pack = (await Pack_Factory.deploy(
    protocolControl.address,
    packContractURI,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarder.address,
  )) as Pack;

  // Deploy Market
  const marketContractURI: string = "";

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Market = (await Market_Factory.deploy(
    protocolControl.address,
    forwarder.address,
    marketContractURI,
  )) as Market;

  // Deploy AccessNFT
  const accessNFTContractURI: string = "";

  const AccessNFT_Factory: ContractFactory = await ethers.getContractFactory("AccessNFT");
  const accessNft: AccessNFT = (await AccessNFT_Factory.deploy(
    protocolControl.address,
    forwarder.address,
    accessNFTContractURI,
  )) as AccessNFT;

  // Get NFT contract
  const NFT_Factory: ContractFactory = await ethers.getContractFactory("NFT");
  const nft: NFT = (await NFT_Factory.deploy(
    protocolControl.address,
    "name",
    "SYMBOL",
    forwarder.address,
    "ipfs://base_uri",
  )) as NFT;

  // Deploy Coin
  const coinName = "";
  const coinSymbol = "";
  const coinURI = "";

  const Coin_Factory: ContractFactory = await ethers.getContractFactory("Coin");
  const coin: Coin = (await Coin_Factory.deploy(
    protocolControl.address,
    coinName,
    coinSymbol,
    forwarder.address,
    coinURI,
  )) as Coin;

  return {
    registry,
    forwarder,
    protocolControl,
    pack,
    market,
    accessNft,
    coin,
    nft,
  };
}
