import { ethers } from "hardhat";
import { chainlinkVars } from "../../utils/chainlink";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

type ContractNames = "AccessNFT" | "Pack" | "Market" | "Forwarder" | "ProtocolControl" | "Coin";

export async function getContracts(
  deployer: SignerWithAddress,
  networkName: string,
  contractNames: ContractNames[],
): Promise<Contract[]> {
  // Deploy Forwarder
  const Forwarder_Factory: ContractFactory = await ethers.getContractFactory("Forwarder");
  const forwarder: Contract = await Forwarder_Factory.deploy();

  // Deploy ProtocolControl

  const admin = deployer.address;
  const nftlabs = deployer.address;
  const protocolControlURI: string = "";

  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const protocolControl: Contract = await ProtocolControl_Factory.deploy(admin, nftlabs, protocolControlURI);

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

  // Deploy Market
  const marketContractURI: string = "";

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(protocolControl.address, forwarder.address, marketContractURI);

  // Deploy AccessNFT
  const accessNFTContractURI: string = "";

  const AccessNFT_Factory: ContractFactory = await ethers.getContractFactory("AccessNFT");
  const accessNft: Contract = await AccessNFT_Factory.deploy(
    protocolControl.address,
    forwarder.address,
    accessNFTContractURI,
  );

  // Deploy Coin
  const coinName = "";
  const coinSymbol = "";
  const coinURI = "";

  const Coin_Factory: ContractFactory = await ethers.getContractFactory("Coin");
  const coin: Contract = await Coin_Factory.deploy(
    protocolControl.address,
    coinName,
    coinSymbol,
    forwarder.address,
    coinURI,
  );

  // Contracts
  const contractstoReturn: Contract[] = [];

  const contracts = {
    Forwarder: forwarder,
    ProtocolControl: protocolControl,
    Pack: pack,
    Market: market,
    AccessNFT: accessNft,
    Coin: coin,
  };

  for (let contractName of contractNames) {
    contractstoReturn.push(contracts[contractName as keyof typeof contracts]);
  }

  return contractstoReturn;
}
