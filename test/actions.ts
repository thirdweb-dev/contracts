import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVars, forkFrom, pairs } from "../utils/utils";

describe("Testing main actions", function() {

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

  it("Create a pack with rewards and list for sale", async () => {
    // Approve handler to transfer reward tokens.
    await accessPacks.connect(creator).setApprovalForAll(handler.address, true);
    // Approve market to transfer pack tokens.
    await pack.connect(creator).setApprovalForAll(market.address, true);

    // Call the Access Packs contract to create rewards.
    await accessPacks.connect(creator).createRewards(rewardURIs, rewardSupplies);

    // Call Handler to create pack with rewards.
    const rewardIds: number[] = [0,1,2];
    await handler.connect(creator).createPack(accessPacks.address, packURI, rewardIds, rewardSupplies);

    // Call Market to list packs on sale.
    const packId: BigNumber = BigNumber.from(0);
    const packQuantityToSell: BigNumber = BigNumber.from(
      rewardSupplies.reduce((a,b) => a+b)
    );
    await market.connect(creator).listPacks(packId, saleCurrency, salePrice, packQuantityToSell);

    // All reward tokens must be locked in the protocol's asset safe.
    for(let i = 0; i < rewardURIs.length; i++) {
      const rewardId: BigNumber = BigNumber.from(i);
      const rewardBalInAssetSafe: BigNumber = BigNumber.from(rewardSupplies[i]);

      expect(await accessPacks.balanceOf(assetSafe.address, rewardId)).to.equal(rewardBalInAssetSafe);
    }

    // All pack tokens must be locked in the protocol's asset safe.
    expect(await pack.balanceOf(assetSafe.address, packId)).to.equal(packQuantityToSell);

    // Creator must have no reward or pack tokens
    expect(await pack.balanceOf(await creator.getAddress(), packId)).to.equal(BigNumber.from(0));

    for(let i = 0; i < rewardURIs.length; i++) {
      const rewardId: BigNumber = BigNumber.from(i);
      expect(await accessPacks.balanceOf(await creator.getAddress(), rewardId)).to.equal(BigNumber.from(0));
    }
  })

  it("Buy pack and open pack", async () => {
    const packId: BigNumber = BigNumber.from(0);
    const packsInAssetSafe: BigNumber = await pack.balanceOf(assetSafe.address, packId);
    const quantityToBuy: BigNumber = BigNumber.from(1);

    // Call the Market contract to buy pack tokens.
    await market.connect(fan).buyPacks(await creator.getAddress(), packId, quantityToBuy, { value: salePrice });
    
    expect(await pack.balanceOf(await fan.getAddress(), packId)).to.equal(quantityToBuy);
    expect(await pack.balanceOf(assetSafe.address, packId)).to.equal(BigNumber.from(
      parseInt(packsInAssetSafe.toString()) - parseInt(quantityToBuy.toString())
    ));
    
    // Approve handler to burn pack tokens
    await pack.connect(fan).setApprovalForAll(handler.address, true);

    // Call the Handler to open pack
    await handler.connect(fan).openPack(packId);
    
    // One pack token should be burned.
    expect(await pack.balanceOf(await fan.getAddress(), packId)).to.equal(BigNumber.from(0));
    
    // Fan should receive one reward token
    let oneRewardReceived: boolean = false;
    let rewardId: BigNumber;
    for(let i = 0; i < rewardURIs.length; i++) {
      const rewardTokenId: BigNumber = BigNumber.from(i);
      const rewardBal = await accessPacks.balanceOf(await fan.getAddress(), rewardTokenId);
      
      if(parseInt(rewardBal.toString()) == 1 && oneRewardReceived) {
        oneRewardReceived = false
        break;        
      } else if (parseInt(rewardBal.toString()) == 1 && !oneRewardReceived) {
        oneRewardReceived = true
        rewardId = rewardTokenId;
      }
    }

    expect(oneRewardReceived).to.equal(true);
  })

  it("Sell reward to another fan", async () => {
    let rewardId: BigNumber = BigNumber.from(0);
    let idx: number = 0;

    for(let i = 0; i < rewardURIs.length; i++) {
      const rewardTokenId: BigNumber = BigNumber.from(i);
      const rewardBal = await accessPacks.balanceOf(await fan.getAddress(), rewardTokenId);

      if(parseInt(rewardBal.toString()) == 1) {
        rewardId = rewardTokenId;
        idx = i
      }
    }

    // Approve Market to handle reward tokens
    await accessPacks.connect(fan).setApprovalForAll(market.address, true);

    expect(await accessPacks.balanceOf(assetSafe.address, rewardId)).to.equal(BigNumber.from(rewardSupplies[idx] - 1));

    // Call Market to list reward token for sale
    await market.connect(fan).listRewards(accessPacks.address, rewardId, saleCurrency, resalePrice, BigNumber.from(1));
    
    // Must lock reward token in access packs contract
    expect(await accessPacks.balanceOf(await fan.getAddress(), rewardId)).to.equal(BigNumber.from(0));
    expect(await accessPacks.balanceOf(assetSafe.address, rewardId)).to.equal(BigNumber.from(rewardSupplies[idx]));
    
    // Call Market to buy reward token
    await market.connect(superFan).buyRewards(accessPacks.address, await fan.getAddress(), rewardId, BigNumber.from(1), { value: resalePrice });
    
    expect(await accessPacks.balanceOf(assetSafe.address, rewardId)).to.equal(BigNumber.from(rewardSupplies[idx] - 1));
    expect(await accessPacks.balanceOf(await superFan.getAddress(), rewardId)).to.equal(BigNumber.from(1));
  })
})