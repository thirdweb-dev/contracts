import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

import { forkFrom } from "../utils/mainnetFork";
import { pairs } from "../utils/ammPairs";
import { chainlinkVars } from "../utils/chainlink";

describe("Testing main actions", function() {

  this.timeout(180000); // Let the tests run for max 3 minutes.

  // Signers
  let protocolAdmin: Signer;
  let creator: Signer;
  let fan: Signer;
  let superFan: Signer;

  // Contracts
  let controlCenter: Contract;
  let pack: Contract
  let market: Contract;
  let rng: Contract;
  let rewards: Contract;
  
  // Test: pack and reward parameters.
  const packURI: string = "This is a dummy Pack URI";
  const numOfRewards: number = 3;
  const rewardURIs: string[] = [];
  const rewardSupplies: BigNumber[] = [];

  let totalPackSupply: BigNumber;
  const secondsUntilStart: BigNumber = BigNumber.from(0)
  const secondsUntilEnd: BigNumber = BigNumber.from(0)

  const saleCurrency: string = "0x0000000000000000000000000000000000000000"; // Zero address == Ether
  const salePrice: BigNumber = ethers.utils.parseEther("1");
  const resalePrice: BigNumber = ethers.utils.parseEther("2");
  
  // Expected listing ID
  const listingId: BigNumber = BigNumber.from(0);
  
  // Test: expected pack token ID and reward token IDs.
  const packId: BigNumber = BigNumber.from(0);
  const rewardIds: BigNumber[] = [0,1,2].map(num => BigNumber.from(num));

  before(async () => {

    // Fork mainnet
    await forkFrom(17304936);

    /// Get Signers
    [protocolAdmin, creator, fan, superFan] = await ethers.getSigners();

    /// Deploy and initialize $PACK Protocol.

    // 1. Deploy ControlCenter
    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    controlCenter = await ProtocolControl_Factory.deploy(await protocolAdmin.getAddress());

    // 2. Deploy rest of the protocol modules.
    const packTokenURI: string = "$PACK Protocol"
    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    pack = await Pack_Factory.deploy(controlCenter.address, packTokenURI);

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    market = await Market_Factory.deploy(controlCenter.address);

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVars.rinkeby;
    const fees: BigNumber = ethers.utils.parseEther("0.1");
    
    const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
    rng = await RNG_Factory.deploy(
      controlCenter.address,
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
    );

    // Initialize $PACK Protocol in ControlCenter
    await controlCenter.initPackProtocol(
      pack.address,
      market.address,
      rng.address,
    );
    
    // Deploy the Rewards contract.
    const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewards = await Rewards_Factory.deploy();

    // Set pack and reward parameters.
    for(let i = 0; i < numOfRewards; i++) {
      rewardURIs.push(`This is dummy reward URI number ${i}`);
      rewardSupplies.push(BigNumber.from(Math.floor(Math.random() * 100) + 10));
    }

    totalPackSupply = BigNumber.from(
      rewardSupplies.reduce((a,b) => BigNumber.from(parseInt(a.toString()) + parseInt(b.toString())))
    );

    // Initialize RNG
    for(let pair of pairs) {
      await rng.addPair(pair.pair);
    }

    // Approve `Pack` to transfer reward tokens.
    await rewards.connect(creator).setApprovalForAll(pack.address, true);
    await rewards.connect(fan).setApprovalForAll(pack.address, true);
    await rewards.connect(superFan).setApprovalForAll(pack.address, true);
    // Approve Market to transfer reward tokens.
    await rewards.connect(creator).setApprovalForAll(market.address, true);
    await rewards.connect(fan).setApprovalForAll(market.address, true);
    await rewards.connect(superFan).setApprovalForAll(market.address, true);
    // Approve market to transfer pack tokens.
    await pack.connect(creator).setApprovalForAll(market.address, true);
    await pack.connect(fan).setApprovalForAll(market.address, true);
    await pack.connect(superFan).setApprovalForAll(market.address, true);
  })  

  it("Create a pack with rewards and list for sale", async () => {

    // Call the Rewards contract to create rewards.
    await rewards.connect(creator).createNativeRewards(rewardURIs, rewardSupplies);

    // Check whether `rewards` mapping in Rewards.sol has updated correctly.
    for(let i = 0; i < rewardURIs.length; i++) {
      const reward = await rewards.rewards(rewardIds[i]);

      expect(reward.creator).to.equal(await creator.getAddress());
      expect(reward.uri).to.equal(rewardURIs[i])
      expect(reward.supply).to.equal(rewardSupplies[i]);
    };

    // Call Pack to create pack with rewards.
    await pack.connect(creator).createPack(packURI, rewards.address, rewardIds, rewardSupplies, secondsUntilStart, secondsUntilEnd);
    
    // Check Market to list packs for sale.
    await market.connect(creator).list(pack.address, packId, saleCurrency, salePrice, totalPackSupply, secondsUntilStart, secondsUntilEnd);

    // Check whether the `listings` mapping in Market.sol has updated correctly.
    const listing = await market.listings(await creator.getAddress(), listingId);

    expect(listing.seller).to.equal(await creator.getAddress());
    expect(listing.assetContract).to.equal(pack.address);
    expect(listing.tokenId).to.equal(packId);
    expect(listing.quantity).to.equal(totalPackSupply);
    expect(listing.currency).to.equal(saleCurrency);
    expect(listing.pricePerToken).to.equal(salePrice);

    // All reward tokens must be locked in the Pack contract.
    for(let i = 0; i < rewardIds.length; i++) {
      const rewardId: BigNumber = rewardIds[i];
      const rewardBalInAssetSafe: BigNumber = BigNumber.from(rewardSupplies[i]);

      expect(await rewards.balanceOf(pack.address, rewardId)).to.equal(rewardBalInAssetSafe);
    }

    // All pack tokens must be locked in the protocol's Market contract.
    expect(await pack.balanceOf(market.address, packId)).to.equal(totalPackSupply);

    // Creator must have no reward or pack tokens
    expect(await pack.balanceOf(await creator.getAddress(), packId)).to.equal(BigNumber.from(0));

    for(let i = 0; i < rewardURIs.length; i++) {
      const rewardId: BigNumber = BigNumber.from(i);
      expect(await rewards.balanceOf(await creator.getAddress(), rewardId)).to.equal(BigNumber.from(0));
    }
  })

  it("Buy pack and open pack", async () => {

    // Call the Market contract to buy pack tokens.
    await market.connect(fan).buy(await creator.getAddress(), listingId, totalPackSupply, { value: salePrice.mul(totalPackSupply) });
    
    // Fan balance of pack should increment by `quantityToBuy`. AssetSafe balance of pack should decrement by `quantityToBuy`.
    expect(await pack.balanceOf(await fan.getAddress(), packId)).to.equal(totalPackSupply);
    expect(await pack.balanceOf(market.address, packId)).to.equal(BigNumber.from(0));

    // Call the Pack to open pack
    await pack.connect(fan).openPack(packId);
    
    // One pack token should be burned.
    expect(await pack.balanceOf(await fan.getAddress(), packId)).to.equal(totalPackSupply.sub(BigNumber.from(1)));
    
    // Fan should receive one reward token
    let oneRewardReceived: boolean = false;
    let rewardId: BigNumber = BigNumber.from(0);
    let idx: number = 0;

    for(let i = 0; i < rewardIds.length; i++) {
      const rewardTokenId: BigNumber = rewardIds[i];
      const rewardBal = await rewards.balanceOf(await fan.getAddress(), rewardTokenId);
      
      if(parseInt(rewardBal.toString()) == 1 && oneRewardReceived) {
        oneRewardReceived = false
        break;        
      } else if (parseInt(rewardBal.toString()) == 1 && !oneRewardReceived) {
        oneRewardReceived = true
        rewardId = rewardTokenId;
        idx = i
      }
    }

    expect(oneRewardReceived).to.equal(true);
    expect(await rewards.balanceOf(pack.address, rewardId)).to.equal(
      parseInt(rewardSupplies[idx].toString()) - 1
    );
  })

  it("Sell reward to another fan", async () => {
    let rewardId: BigNumber = BigNumber.from(0);
    
    for(let i = 0; i < rewardIds.length; i++) {
      const rewardTokenId: BigNumber = rewardIds[i];
      const rewardBal = await rewards.balanceOf(await fan.getAddress(), rewardTokenId);

      if(parseInt(rewardBal.toString()) == 1) {
        rewardId = rewardTokenId;
      }
    }

    // Call Market to list reward token for sale
    await market.connect(fan).list(rewards.address, rewardId, saleCurrency, resalePrice, BigNumber.from(1), secondsUntilStart, secondsUntilEnd);
    
    // Must lock reward token in access packs contract
    expect(await rewards.balanceOf(await fan.getAddress(), rewardId)).to.equal(BigNumber.from(0));
    expect(await rewards.balanceOf(market.address, rewardId)).to.equal(BigNumber.from(1));
    
    // Call Market to buy reward token
    await market.connect(superFan).buy( await fan.getAddress(), listingId, BigNumber.from(1), { value: resalePrice });
    
    expect(await rewards.balanceOf(market.address, rewardId)).to.equal(BigNumber.from(0));
    expect(await rewards.balanceOf(await superFan.getAddress(), rewardId)).to.equal(BigNumber.from(1));
  })
})