import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber, BytesLike } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom } from "../utils/hardhatFork";
import { setTimeout } from "timers";

describe("List packs on sale using Market.sol", function () {
  // Signers
  let protocolAdmin: Signer;
  let creator: Signer;
  let fan: Signer;

  // Contracts
  let controlCenter: Contract;
  let pack: Contract;
  let rewards: Contract;
  let market: Contract;
  let coin: Contract;

  // Reward parameterrs
  const rewardURIs: string[] = [
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
  ];
  const rewardSupplies: number[] = [5, 10, 20];

  // Pack parameters
  const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const openStartAndEnd: number = 0;

  // Expected results
  const expectedPackId: number = 0;
  const expectedPackSupply: number = rewardSupplies.reduce((a, b) => a + b);

  // List packs on sale: Market parameters
  const expectedListingId: number = 0;
  let currency: string = "";
  const pricePerToken: BigNumber = ethers.utils.parseEther("1");
  const saleWindowLimits: number = 0;

  beforeEach(async () => {
    // Fork rinkeby
    await forkFrom(9075707, "rinkeby");

    const signers: Signer[] = await ethers.getSigners();
    [protocolAdmin, creator, fan] = signers;

    // Deploy $PACK Protocol
    const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars.rinkeby;

    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    controlCenter = await ProtocolControl_Factory.deploy();

    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    pack = await Pack_Factory.deploy(
      controlCenter.address,
      "$PACK Protocol",
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees,
    );

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    market = await Market_Factory.deploy(controlCenter.address);

    await controlCenter.initializeProtocol(pack.address, market.address);

    // Deploy Rewardds.sol and create rewards
    const Rewards_factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewards = await Rewards_factory.connect(creator).deploy(pack.address);

    // Create pack with rewards.
    await rewards
      .connect(creator)
      .createPackAtomic(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd);

    // deploy fake ERC20 for pricing packs
    const Coin_Factory: ContractFactory = await ethers.getContractFactory("Coin");
    coin = await Coin_Factory.connect(protocolAdmin).deploy();

    await coin.connect(protocolAdmin).mint(await fan.getAddress(), ethers.utils.parseEther("35"));

    currency = coin.address;
  });

  describe("Revert cases", function () {
    it("Should revert is zero tokens are being listed", async () => {
      await expect(
        market
          .connect(creator)
          .list(pack.address, expectedPackId, currency, pricePerToken, 0, saleWindowLimits, saleWindowLimits),
      ).to.be.revertedWith("Market: must list at least one token.");
    });

    it("Should revert if Matket is not approved to transfer tokens", async () => {
      await expect(
        market
          .connect(creator)
          .list(
            pack.address,
            expectedPackId,
            currency,
            pricePerToken,
            expectedPackSupply,
            saleWindowLimits,
            saleWindowLimits,
          ),
      ).to.be.revertedWith("Market: must approve the market to transfer tokens being listed.");
    });
  });

  describe("Events", function () {
    it("Should emit NewListing with listing info", async () => {
      // Approve market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);

      const newListingPromise = new Promise((resolve, reject) => {
        market.on("NewListing", async (_asset, _seller, _listingId, _listing) => {
          expect(_asset).to.equal(pack.address);
          expect(_seller).to.equal(await creator.getAddress());
          expect(_listingId).to.equal(expectedListingId);

          expect(_listing.tokenId).to.equal(expectedPackId);
          expect(_listing.currency).to.equal(currency);
          expect(_listing.pricePerToken).to.equal(pricePerToken);

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: NewListing"));
        }, 5000);
      });

      await market
        .connect(creator)
        .list(
          pack.address,
          expectedPackId,
          currency,
          pricePerToken,
          expectedPackSupply,
          saleWindowLimits,
          saleWindowLimits,
        );
      await newListingPromise;
    });
  });

  describe("Balances", function () {
    it("Should lock all tokens being listed in the Market", async () => {
      // Approve market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);

      // List on market
      await market
        .connect(creator)
        .list(
          pack.address,
          expectedPackId,
          currency,
          pricePerToken,
          expectedPackSupply,
          saleWindowLimits,
          saleWindowLimits,
        );

      expect(await pack.balanceOf(market.address, expectedPackId)).to.equal(expectedPackSupply);
      expect(await pack.balanceOf(await creator.getAddress(), expectedPackId)).to.equal(0);
    });
  });

  describe("Contract state changes", function () {
    it("Should increment totalListings by one", async () => {
      // Approve market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);

      // List on market
      await market
        .connect(creator)
        .list(
          pack.address,
          expectedPackId,
          currency,
          pricePerToken,
          expectedPackSupply,
          saleWindowLimits,
          saleWindowLimits,
        );

      expect(await market.totalListings()).to.equal(1);
    });

    it("Should update the listings with info about the new listing", async () => {
      // Approve market to transfer packs
      await pack.connect(creator).setApprovalForAll(market.address, true);

      // List on market
      await market
        .connect(creator)
        .list(
          pack.address,
          expectedPackId,
          currency,
          pricePerToken,
          expectedPackSupply,
          saleWindowLimits,
          saleWindowLimits,
        );

      const listing = await market.listings(expectedListingId);

      expect(listing.assetContract).to.equal(pack.address);
      expect(listing.seller).to.equal(await creator.getAddress());
      expect(listing.tokenId).to.equal(expectedPackId);
      expect(listing.currency).to.equal(currency);
      expect(listing.pricePerToken).to.equal(pricePerToken);
    });
  });
});
