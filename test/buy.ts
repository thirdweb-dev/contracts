import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber, BytesLike } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom } from "../utils/hardhatFork";
import { setTimeout } from "timers";

describe("Buy packs using Market.sol", function () {
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

  // Buy packs from market: Market parameters
  const quantityToBuy: BigNumber = BigNumber.from(1);

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

    // List packs on sale
    await pack.connect(creator).setApprovalForAll(market.address, true);
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
  });

  describe("Revert cases", function () {
    it("Should revert if no quantity of tokens are bought", async () => {
      await expect(market.connect(fan).buy(expectedListingId, 0)).to.be.revertedWith(
        "Market: must buy an appropriate amount of tokens.",
      );
    });

    it("Should revert if more tokens than are listed, are bought", async () => {
      await expect(market.connect(fan).buy(expectedListingId, expectedPackSupply + 1)).to.be.revertedWith(
        "Market: must buy an appropriate amount of tokens.",
      );
    });

    it("Should revert is Market is not approved to spend the required amount of currency", async () => {
      await expect(market.connect(fan).buy(expectedListingId, quantityToBuy)).to.be.revertedWith(
        "Market: must approve Market to transfer price to pay.",
      );
    });
  });

  describe("Events", function () {
    it("Should emit NewSale with all info about the sale", async () => {
      // Approve market to transfer price amount
      await coin.connect(fan).approve(market.address, quantityToBuy.mul(pricePerToken));

      const newSalePromise = new Promise((resolve, reject) => {
        market.on("NewSale", async (_assetContract, _seller, _listingId, _buyer, _listing) => {
          expect(_assetContract).to.equal(pack.address);
          expect(_seller).to.equal(await creator.getAddress());
          expect(_listingId).to.equal(expectedListingId);
          expect(_buyer).to.equal(await fan.getAddress());

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: NewSale"));
        }, 5000);
      });

      await market.connect(fan).buy(expectedListingId, quantityToBuy);
      await newSalePromise;
    });
  });

  describe("Balances", function () {
    it("Should transfer the relevant amounts of the listed tokens to the buyer", async () => {
      // Approve market to transfer price amount
      await coin.connect(fan).approve(market.address, quantityToBuy.mul(pricePerToken));

      await market.connect(fan).buy(expectedListingId, quantityToBuy);

      expect(await pack.balanceOf(market.address, expectedPackId)).to.equal(
        BigNumber.from(expectedPackSupply).sub(quantityToBuy),
      );
      expect(await pack.balanceOf(await fan.getAddress(), expectedPackId)).to.equal(quantityToBuy);
    });

    it("Should transfer the appropriate shares of the price paid by the buyer", async () => {
      const fanBalBefore: BigNumber = await coin.balanceOf(await fan.getAddress());
      const creatorBalBefore: BigNumber = await coin.balanceOf(await creator.getAddress());
      const protocolBalBefore: BigNumber = await coin.balanceOf(controlCenter.address);

      // Approve market to transfer price amount
      await coin.connect(fan).approve(market.address, quantityToBuy.mul(pricePerToken));

      await market.connect(fan).buy(expectedListingId, quantityToBuy);

      const MAX_BPS: BigNumber = await market.MAX_BPS();
      const protocolCut: BigNumber = await market.protocolFeeBps();

      const fanBalAfter: BigNumber = await coin.balanceOf(await fan.getAddress());
      const creatorBalAfter: BigNumber = await coin.balanceOf(await creator.getAddress());
      const protocolBalAfter: BigNumber = await coin.balanceOf(controlCenter.address);

      const totalPrice: BigNumber = quantityToBuy.mul(pricePerToken);
      const protocolFee: BigNumber = totalPrice.mul(protocolCut).div(MAX_BPS);

      expect(fanBalBefore.sub(fanBalAfter)).to.equal(totalPrice);
      expect(protocolBalAfter.sub(protocolBalBefore)).to.equal(protocolFee);
      expect(creatorBalAfter.sub(creatorBalBefore)).to.equal(totalPrice.sub(protocolFee));
    });
  });

  describe("Contract state changes", function () {
    it("Should update decrease the quantity listed by the amount bought", async () => {
      const listingBeforePurchase = await market.listings(expectedListingId);
      const qtyBefore: BigNumber = listingBeforePurchase.quantity;

      // Approve market to transfer price amount
      await coin.connect(fan).approve(market.address, quantityToBuy.mul(pricePerToken));

      await market.connect(fan).buy(expectedListingId, quantityToBuy);

      const listingAfterPurchase = await market.listings(expectedListingId);
      const qtyAfter: BigNumber = listingAfterPurchase.quantity;

      expect(qtyBefore.sub(qtyAfter)).to.equal(quantityToBuy);
    });
  });
});
