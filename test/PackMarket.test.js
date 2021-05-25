const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

chai.use(solidity);
const { expect } = chai;

describe("PackMarket", async () => {
  let pack;
  let packMarket;
  let packCoin;
  let owner;
  let buyer;
  let currency;

  const uri = "100";
  const supply = 100;
  const price = 10;
  const quantity = 1;

  before(async () => {
    signers = await ethers.getSigners();
    [owner, buyer] = signers;
  })

  beforeEach(async () => {
    const Pack = await ethers.getContractFactory("Pack", owner);
    pack = await Pack.deploy();

    const PackCoin = await ethers.getContractFactory("PackCoin", owner);
    packCoin = await PackCoin.deploy();
    currency = packCoin.address;

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
      await pack.lockReward(tokenId);

      try {
        await packMarket.sell(tokenId, currency, price, quantity);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("Must approve market contract to manage tokens");
      }
    })

    it("sell must own enough tokens", async () => {
      await pack.lockReward(tokenId);
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.safeTransferFrom(owner.address, buyer.address, tokenId, supply, "0x00");

      try {
        await packMarket.sell(tokenId, currency, price, quantity);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("Must own the amount of tokens being listed");
      }
    })

    it("sell must list at least one token", async () => {
      await pack.lockReward(tokenId);
      await pack.setApprovalForAll(packMarket.address, true);

      try {
        await packMarket.sell(tokenId, currency, price, 0);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("Must list at least one token");
      }
    })

    it("sell requires locked pack", async () => {
      await pack.setApprovalForAll(packMarket.address, true);

      try {
        await packMarket.sell(tokenId, currency, price, quantity);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("attempting to sell unlocked pack");
      }
    })

    it("sell creates listing", async () => {
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);
      
      const listing = await packMarket.listings(owner.address, tokenId);
      expect(listing.owner).to.equal(owner.address);
      expect(listing.tokenId).to.equal(tokenId);
      expect(listing.currency).to.equal(currency);
      expect(listing.price).to.equal(price);
    })

    it("sell emits PackListed", async () => {
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);

      expect(await packMarket.sell(tokenId, currency, price, quantity))
        .to
        .emit(packMarket, "NewListing")
        .withArgs(owner.address, tokenId, true, currency, price, quantity);
    })
  })

  describe("unlist", async () => {
    let tokenId;

    beforeEach(async () => {
      const packToken = await pack.createPack(uri, supply);
      tokenId = packToken.value;

      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);
    })

    it("unlist listing must exist", async () => {
      try {
        await packMarket.unlist(tokenId + 1);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("listing must exist");
      }
    })

    it("unlist removes listing", async () => {
      await packMarket.unlist(tokenId);

      const listing = await packMarket.listings(owner.address, tokenId)
      expect(listing.quantity).to.equal(0);
    })

    it("unlist emits PackUnlisted", async () => {
      expect(await packMarket.unlist(tokenId))
        .to
        .emit(packMarket, "PackUnlisted")
        .withArgs(owner.address, tokenId);
    })
  })

  describe("buy", async () => {
    let tokenId;

    beforeEach(async () => {
      const packToken = await pack.createPack(uri, supply);
      tokenId = packToken.value;
    })

    it("buy must buy at least one token", async () => {
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);

      await packCoin.mint(buyer.address, price);
      await packCoin.connect(buyer).approve(packMarket.address, price);

      try {
        await packMarket.connect(buyer).buy(owner.address, tokenId, 0);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("must buy at least one token");
      }
    })

    it("buy cannot buy more than listed quantity", async () => {
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);

      await packCoin.mint(buyer.address, price * 2);
      await packCoin.connect(buyer).approve(packMarket.address, price * 2);

      try {
        await packMarket.connect(buyer).buy(owner.address, tokenId, quantity + 1);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("attempting to buy more tokens than listed");
      }
    })

    it("buy successfully transfers Pack", async () => {
      expect(await pack.balanceOf(buyer.address, tokenId)).to.equal(0);

      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);

      await packCoin.mint(buyer.address, price);
      await packCoin.connect(buyer).approve(packMarket.address, price);
      await packMarket.connect(buyer).buy(owner.address, tokenId, quantity);

      expect(await pack.balanceOf(buyer.address, tokenId)).to.equal(1);
    })

    it("buy emits PackSold", async () => {
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);

      await packCoin.mint(buyer.address, price);
      await packCoin.connect(buyer).approve(packMarket.address, price);

      expect(await packMarket.connect(buyer).buy(owner.address, tokenId, quantity))
        .to
        .emit(packMarket, "PackSold")
        .withArgs(owner.address, buyer.address, tokenId, 1);
    })
  })
})