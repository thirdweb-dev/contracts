const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

chai.use(solidity);
const { expect } = chai;

describe("PackMarket", async () => {
  let pack;
  let packMarket;
  let owner;
  let buyer;

  const uri = "100";
  const supply = 100;
  const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const amount = 10;

  before(async () => {
    signers = await ethers.getSigners();
    [owner, buyer] = signers;
  })

  beforeEach(async () => {
    const Pack = await ethers.getContractFactory("Pack", owner);
    pack = await Pack.deploy();

    const PackMarket = await ethers.getContractFactory("PackMarket", owner);
    packMarket = await PackMarket.deploy(pack.address);
  })

  describe("setPackToken", async () => {
    let anotherPack;

    beforeEach(async () => {
      const Pack = await ethers.getContractFactory("Pack", owner);
      anotherPack = await Pack.deploy();
    })
    
    it("setPackToken only owner can change Pack", async () => {
      expect(await packMarket.packToken()).to.equal(pack.address);

      try {
        await packMarket.connect(buyer).setPackToken(anotherPack.address);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("caller is not the owner");
      }

      await packMarket.setPackToken(anotherPack.address);
      expect(await packMarket.packToken()).to.equal(anotherPack.address);

    })

    it("setPackToken emits PackTokenChange", async () => {
      expect(await packMarket.setPackToken(anotherPack.address))
        .to
        .emit(packMarket, "PackTokenChanged")
        .withArgs(anotherPack.address);
    })
  })

  describe("sell", async () => {
    let tokenId;

    beforeEach(async () => {
      const packToken = await pack.createPack(uri, supply);
      tokenId = packToken.value;
    })

    it("sell requires token approval", async () => {
      try {
        await packMarket.sell(tokenId, USDC, amount);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("require token approval");
      }
    })

    it("sell requires at least one token", async () => {
      try {
        await pack.setApprovalForAll(packMarket.address, true);
        await pack.safeTransferFrom(owner.address, buyer.address, tokenId, supply, "0x00");
        await packMarket.sell(tokenId, USDC, amount);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("require at least 1 token");
      }
    })

    it("sell requires locked pack", async () => {
      await pack.setApprovalForAll(packMarket.address, true);

      try {
        await packMarket.sell(tokenId, USDC, amount);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("attempting to sell unlocked pack");
      }
    })

    it("sell creates listing", async () => {
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, USDC, amount);
      
      const listing = await packMarket.listings(owner.address, tokenId);
      expect(listing.owner).to.equal(owner.address);
      expect(listing.tokenId).to.equal(tokenId);
      expect(listing.currency).to.equal(USDC);
      expect(listing.amount).to.equal(amount);
    })

    it("sell emits PackListed", async () => {

    })
  })

  describe("buy", async () => {
    it("buy successfully transfers Pack", async () => {
      
    })

    it("buy emits PackSold", async () => {

    })
  })
})