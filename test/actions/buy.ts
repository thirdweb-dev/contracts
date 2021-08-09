import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../../utils/chainlink";

describe("Buy packs using Market.sol", function() {
  // Signers.
  let deployer: Signer;
  let creator: Signer;
  let fan: Signer;

  // Contracts.
  let rewardsContract: Contract;
  let pack: Contract;
  let market: Contract;

  // Reward parameters.
  let numOfRewards: number = 5;
  const rewardURIs: string[] = [];
  const rewardSupplies: BigNumber[] = [];

  // Pack parameters.
  const expectedPackId: BigNumber = BigNumber.from(0)
  const packURI: string = "This is a dummy pack";
  const rewardIds: BigNumber[] = [];
  const openPackLimits: BigNumber = BigNumber.from(0)
  let packTotalSupply: BigNumber = BigNumber.from(0);

  // List packs on sale: Market parameters
  const expectedListingId: BigNumber = BigNumber.from(0);
  const currency: string = "0x0000000000000000000000000000000000000000";
  const pricePerToken: BigNumber = ethers.utils.parseEther("0.01");
  const saleWindowLimits: BigNumber = BigNumber.from(0)

  // Buy packs from market: Market parameters
  const quantityToBuy: BigNumber = BigNumber.from(1)

  before(() => {
    // Fill in reward and pack parameters
    for(let i = 0; i < numOfRewards; i++) {

      // Reward params
      rewardURIs.push(`This is a dummy URI - ${i}`);
      rewardSupplies.push(
        BigNumber.from(
          Math.floor(Math.random() * 100) + 10
        )
      );

      // Pack params;
      rewardIds.push(BigNumber.from(i));
      packTotalSupply = packTotalSupply.add(rewardSupplies[i]);
    }
  })

  beforeEach(async () => {
    // Get signers
    [deployer, creator, fan] = await ethers.getSigners();
    
    // Get contracts.
    const RewardsContract_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewardsContract = await RewardsContract_Factory.connect(deployer).deploy();

    // 1. Deploy ControlCenter
    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    const controlCenter: Contract = await ProtocolControl_Factory.deploy(await deployer.getAddress());

    // 2. Deploy rest of the protocol modules.
    const packContractURI: string = "$PACK Protocol"
    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    pack = await Pack_Factory.deploy(controlCenter.address, packContractURI);

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    market = await Market_Factory.deploy(controlCenter.address);

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVars.rinkeby;
    const fees: BigNumber = ethers.utils.parseEther("0.1");
    
    const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
    const rng: Contract = await RNG_Factory.deploy(
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

    // Create rewards
    await rewardsContract.connect(creator).createNativeRewards(rewardURIs, rewardSupplies)

    // Create pack
    await rewardsContract.connect(creator).setApprovalForAll(pack.address, true);
    await pack.connect(creator).createPack(packURI, rewardsContract.address, rewardIds, rewardSupplies, openPackLimits, openPackLimits);

    // List packs on sale
    await pack.connect(creator).setApprovalForAll(market.address, true);
    await market.connect(creator).list(pack.address, expectedPackId, currency, pricePerToken, packTotalSupply, saleWindowLimits, saleWindowLimits);
  })

  describe("Revert cases", function() {

    it("Should revert if the incorrect seller address or listing ID are provided", async () => {
      const invalidListingId: BigNumber = expectedListingId.add(BigNumber.from(1));

      await expect(market.connect(fan).buy(await creator.getAddress(), invalidListingId, quantityToBuy, { value: pricePerToken.mul(quantityToBuy)}))
        .to.be.revertedWith("Market: The listing does not exist.")
      await expect(market.connect(fan).buy(await deployer.getAddress(), expectedListingId, quantityToBuy))
        .to.be.revertedWith("Market: The listing does not exist.")
    })

    it("Should revert if the quantity to buy is greater than the quantity listed for sale", async () => {
      await expect(market.connect(fan).buy(await creator.getAddress(), expectedListingId, packTotalSupply.add(quantityToBuy), { value: pricePerToken.mul(packTotalSupply.add(quantityToBuy))}))
        .to.be.revertedWith("Market: trying to buy more tokens than are listed.")
    })

    it("Should revert if not enough ether is sent to buy packs", async () => {
      await expect(market.connect(fan).buy(await creator.getAddress(), expectedListingId, quantityToBuy))
        .to.be.revertedWith("Market: must send enough ether to pay the price.")
    })
  })

  describe("Events", function() {

    it("Should emit NewSale with info about the sale", async () => {
      await expect(market.connect(fan).buy(await creator.getAddress(), expectedListingId, quantityToBuy, { value: pricePerToken.mul(quantityToBuy)}))
        .to.emit(market, "NewSale")
        .withArgs(pack.address, await creator.getAddress(), expectedListingId, await fan.getAddress(), expectedPackId, currency, pricePerToken, quantityToBuy)
    })    
  })

  describe("Balances", function() {

    let treasuryBalBefore: BigNumber;
    let creatorBalBefore: BigNumber;

    beforeEach(async () => {
      treasuryBalBefore = await deployer.getBalance()
      creatorBalBefore = await creator.getBalance()

      // Buy packs
      await market.connect(fan).buy(await creator.getAddress(), expectedListingId, quantityToBuy, { value: pricePerToken.mul(quantityToBuy)})
    })
    
    it("Should transfer the right amount of packs from the Market to the buyer", async () => {
      expect(await pack.balanceOf(market.address, expectedPackId)).to.equal(packTotalSupply.sub(quantityToBuy))
      expect(await pack.balanceOf(await fan.getAddress(), expectedPackId)).to.equal(quantityToBuy);
    })

    it("Should transfer away ether from the buyer and correctly distribute it to the creator and protocol", async () => {
      const treasuryBal:  BigNumber = await deployer.getBalance()
      const creatorBal: BigNumber = await creator.getBalance();

      const totalPricePaid: BigNumber = pricePerToken.mul(quantityToBuy)

      const protocolCut: BigNumber = (totalPricePaid.mul(BigNumber.from(500))).div(BigNumber.from(10000)) // 5 %

      expect(treasuryBal.sub(treasuryBalBefore)).to.equal(protocolCut)
      expect(creatorBal.sub(creatorBalBefore)).to.equal(totalPricePaid.sub(protocolCut))
    })
  })

  describe("Contract state changes", function() {
    beforeEach(async () => {
      // Buy packs
      await market.connect(fan).buy(await creator.getAddress(), expectedListingId, quantityToBuy, { value: pricePerToken.mul(quantityToBuy)})
    })

    it("Should update the `listing` mapping with new quantity to list for sale", async () => {
      const listing = await market.listings(await creator.getAddress(), expectedListingId)

      expect(listing.quantity).to.equal(packTotalSupply.sub(quantityToBuy));
    })
  })
})