import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVars, forkFrom, pairs } from "../utils/utils";

describe("Testing main contract actions", function() {
  this.timeout(180000); // Let the tests run for max 3 minutes.

  let protocolAdmin: Signer;
  let creator: Signer;
  let fan: Signer;
  let superFan: Signer;

  let controlCenter: Contract;
  let pack: Contract
  let handler: Contract;
  let market: Contract;
  let rng: Contract;
  let assetSafe: Contract;
  let accessPacks: Contract;

  const forkBlock = Math.floor(Math.random() * 1000) + 12000000;

  const packURI: string = "This is a dummy Pack URI";
  const numOfRewards: number = 3;
  const rewardURIs: string[] = [];
  const rewardSupplies: number[] = [];

  const saleCurrency: string = "0x0000000000000000000000000000000000000000"; // Zero address == Ether
  const salePrice: BigNumber = ethers.utils.parseEther("1");
  const resalePrice: BigNumber = ethers.utils.parseEther("2");

  before(async () => {

    // Fork mainnet
    await forkFrom(forkBlock);

    /// Get Signers
    [protocolAdmin, creator, fan, superFan] = await ethers.getSigners();

    /// Deploy and initialize $PACK Protocol contracts. 
    const ControlCenter_Factory: ContractFactory = await ethers.getContractFactory("ControlCenter");
    controlCenter = await ControlCenter_Factory.deploy(await protocolAdmin.getAddress());

    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    pack = await Pack_Factory.deploy(controlCenter.address);

    const Handler_Factory: ContractFactory = await ethers.getContractFactory("Handler");
    handler = await Handler_Factory.deploy(controlCenter.address);

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    market = await Market_Factory.deploy(controlCenter.address);

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVars;
    
    const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
    rng = await RNG_Factory.deploy(
      controlCenter.address,
      vrfCoordinator,
      linkTokenAddress,
      keyHash
    );

    const AssetSafe_Factory: ContractFactory = await ethers.getContractFactory("AssetSafe");
    assetSafe = await AssetSafe_Factory.deploy(controlCenter.address);

    await controlCenter.initPackProtocol(
      pack.address,
      handler.address,
      market.address,
      rng.address,
      assetSafe.address
    );
    
    // Deploy the Access Packs contract.
    const AccessPacks_Factory: ContractFactory = await ethers.getContractFactory("AccessPacks");
    accessPacks = await AccessPacks_Factory.deploy();

    // Fill up reward URIs and reward supplies
    for(let i = 0; i < numOfRewards; i++) {
      rewardURIs.push(`This is dummy reward URI number ${i}`);
      rewardSupplies.push(Math.floor(Math.random() * 100) + 10);
    }

    // Setup RNG
    for(let pair of pairs) {
      await rng.connect(protocolAdmin).addPair(pair.pair);
    }
  })
})