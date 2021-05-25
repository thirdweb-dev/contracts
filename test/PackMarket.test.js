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
        expect(err.message).to.contain("Cannot sell an unlocked pack or a token that has not been minted");
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

    it("sell emits NewListing", async () => {
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
        expect(err.message).to.contain("Only the seller can modify the listing.");
      }
    })

    it("unlist onlySeller can update", async () => {
      try {
        await packMarket.connect(buyer).unlist(tokenId);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("Only the seller can modify the listing.");
      }
    })

    it("unlist inactivates listing", async () => {
      await packMarket.unlist(tokenId);

      const listing = await packMarket.listings(owner.address, tokenId)
      expect(listing.active).to.equal(false);
    })

    it("unlist emits ListingUpdate", async () => {
      expect(await packMarket.unlist(tokenId))
        .to
        .emit(packMarket, "ListingUpdate")
        .withArgs(owner.address, tokenId, false, currency, price, quantity);
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

    it("buy emits NewSale", async () => {
      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);

      await packCoin.mint(buyer.address, price * quantity);
      await packCoin.connect(buyer).approve(packMarket.address, price * quantity);

      expect(await packMarket.connect(buyer).buy(owner.address, tokenId, quantity))
        .to
        .emit(packMarket, "NewSale")
        .withArgs(owner.address, buyer.address, tokenId, currency, price, quantity);
    })
  })

  describe("edit listing", async () => {
    let tokenId;

    beforeEach(async () => {
      const packToken = await pack.createPack(uri, supply);
      tokenId = packToken.value;

      await pack.setApprovalForAll(packMarket.address, true);
      await pack.lockReward(tokenId);
      await packMarket.sell(tokenId, currency, price, quantity);
    })

    it("setListingPrice changes price", async () => {
      const listing = await packMarket.listings(owner.address, tokenId)
      expect(listing.price).to.equal(price);

      await packMarket.setListingPrice(tokenId, price + 1);

      const newListing = await packMarket.listings(owner.address, tokenId)
      expect(newListing.price).to.equal(price + 1);
    })

    it("setListingPrice emits ListingUpdate", async () => {
      expect(await packMarket.setListingPrice(tokenId, price + 1))
        .to
        .emit(packMarket, "ListingUpdate")
        .withArgs(owner.address, tokenId, true, currency, price + 1, quantity);
    })

    it("setListingCurrency changes currency", async () => {
      const listing = await packMarket.listings(owner.address, tokenId)
      expect(listing.currency).to.equal(currency);

      const PackCoin = await ethers.getContractFactory("PackCoin", owner);
      const newPackCoin = await PackCoin.deploy();
      const newCurrency = newPackCoin.address;
      await packMarket.setListingCurrency(tokenId, newCurrency);

      const newListing = await packMarket.listings(owner.address, tokenId)
      expect(newListing.currency).to.equal(newCurrency);
    })

    it("setListingCurrency emits ListingUpdate", async () => {
      const PackCoin = await ethers.getContractFactory("PackCoin", owner);
      const newPackCoin = await PackCoin.deploy();
      const newCurrency = newPackCoin.address;
      
      expect(await packMarket.setListingCurrency(tokenId, newCurrency))
        .to
        .emit(packMarket, "ListingUpdate")
        .withArgs(owner.address, tokenId, true, newCurrency, price, quantity)

    })

  })
})