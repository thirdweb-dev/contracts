import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVarsRinkeby } from "../../utils/chainlink";

describe("List packs for sale using Market.sol", function() {
  // Signers.
  let deployer: Signer;
  let creator: Signer;

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
    [deployer, creator] = await ethers.getSigners();
    
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

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVarsRinkeby;
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
    await pack.connect(creator).createPack(
      packURI,
      rewardsContract.address,
      rewardIds,
      rewardSupplies,
      openPackLimits,
      openPackLimits
    )
  })

  describe("Revert cases", function() {

    it("Should revert if Market is not approved to transfer the tokens being listed", async () => {
      await expect(market.connect(creator).list(
        pack.address,
        expectedPackId,
        currency,
        pricePerToken,
        packTotalSupply,
        saleWindowLimits,
        saleWindowLimits
      ))
      .to.be.revertedWith("Market: must approve the market to transfer tokens being listed.")
    })

    it("Should revert if no quantity of tokens is being listed", async () => {
      // Approve Market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);

      await expect(market.connect(creator).list(
        pack.address,
        expectedPackId,
        currency,
        pricePerToken,
        BigNumber.from(0),
        saleWindowLimits,
        saleWindowLimits
      ))
      .to.be.revertedWith("Market: must list at least one token.")
    })
  })

  describe("Events", function() {
    beforeEach(async () => {
      // Approve Market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);
    })

    it("Should emit NewListing with all relevant listing info", async () => {
      expect(await market.connect(creator).list(
        pack.address,
        expectedPackId,
        currency,
        pricePerToken,
        packTotalSupply,
        saleWindowLimits,
        saleWindowLimits
      ))
      .to.emit(market, "NewListing")
      .withArgs(pack.address, await creator.getAddress(), expectedListingId, expectedPackId, currency, pricePerToken, packTotalSupply)
    })

    it("Should emit SaleWindowUpdate with info related to the sale start and end", async () => {
      const saleWindowPromise = new Promise((resolve, reject) => {
        market.on("SaleWindowUpdate", async (_seller, _listingId) => {
          expect(_seller).to.equal(await creator.getAddress())
          expect(_listingId).to.equal(expectedListingId)

          resolve(null);
        })

        setTimeout(() => {
          reject(new Error("Event timeout: SaleWindowUpdate"));
        }, 5000);
      })

      await market.connect(creator).list(
        pack.address,
        expectedPackId,
        currency,
        pricePerToken,
        packTotalSupply,
        saleWindowLimits,
        saleWindowLimits
      )

      await saleWindowPromise;
    })
  })

  describe("Balances", function() {
    beforeEach(async () => {
      // Approve Market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);
      // List packs on sale
      await market.connect(creator).list(
        pack.address,
        expectedPackId,
        currency,
        pricePerToken,
        packTotalSupply,
        saleWindowLimits,
        saleWindowLimits
      )
    })

    it("Should transfer all packs from the creator to the Market", async () => {
      expect(await pack.balanceOf(await creator.getAddress(), expectedPackId)).to.equal(BigNumber.from(0));
      expect(await pack.balanceOf(market.address, expectedPackId)).to.equal(packTotalSupply);
    })
  })

  describe("Contract state changes", function() {
    beforeEach(async () => {
      // Approve Market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);
      // List packs on sale
      await market.connect(creator).list(
        pack.address,
        expectedPackId,
        currency,
        pricePerToken,
        packTotalSupply,
        saleWindowLimits,
        saleWindowLimits
      )
    })

    it("Should update the `totalListings` mapping for the creator", async () => {
      expect(await market.totalListings(await creator.getAddress())).to.equal(expectedListingId.add(BigNumber.from(1)))
    })

    it("Should update the `listings` mapping with all listing info", async () => {
      const listing = await market.listings(await creator.getAddress(), expectedListingId);

      expect(listing.seller).to.equal(await creator.getAddress());
      expect(listing.assetContract).to.equal(pack.address);
      expect(listing.tokenId).to.equal(expectedPackId);
      expect(listing.quantity).to.equal(packTotalSupply);
      expect(listing.currency).to.equal(currency);
      expect(listing.pricePerToken).to.equal(pricePerToken);
    })
  })
})