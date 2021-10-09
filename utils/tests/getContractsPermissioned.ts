import { ethers } from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import { ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { AccessNFT } from "../../typechain/AccessNFT";
import { NFT } from "../../typechain/NFT";
import { Coin } from "../../typechain/Coin";
import { Pack } from "../../typechain/Pack";
import { Market } from "../../typechain/Market";
import { Forwarder } from "../../typechain/Forwarder";
import { NFTWrapper } from "../../typechain/NFTWrapper";
import { ProtocolControl } from "../../typechain/ProtocolControl";

export type Contracts = {
  forwarder: Forwarder;
  protocolControl: ProtocolControl;
  accessNft: AccessNFT;
  coin: Coin;
  pack: Pack;
  market: Market;
  nftWrapper: NFTWrapper;
  nft: NFT;
};

export async function getContracts(deployer: SignerWithAddress, networkName: string): Promise<Contracts> {
  // Deploy Forwarder
  const Forwarder_Factory: ContractFactory = await ethers.getContractFactory("Forwarder");
  const forwarder: Forwarder = (await Forwarder_Factory.deploy()) as Forwarder;

  // Deploy NFTWrapper
  const NFTWrapper_Factory: ContractFactory = await ethers.getContractFactory("NFTWrapper");
  const nftWrapper: NFTWrapper = (await NFTWrapper_Factory.deploy()) as NFTWrapper;

  // Deploy ProtocolControl

  const admin = deployer.address;
  const protocolProvider = deployer.address;
  const providerTreasury = deployer.address;
  const protocolControlURI: string = "";

  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const protocolControl: ProtocolControl = (await ProtocolControl_Factory.deploy(
    admin,
    protocolProvider,
    providerTreasury,
    protocolControlURI,
  )) as ProtocolControl;

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
    nftWrapper.address,
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
    forwarder,
    protocolControl,
    pack,
    market,
    accessNft,
    coin,
    nftWrapper,
    nft,
  };
}
