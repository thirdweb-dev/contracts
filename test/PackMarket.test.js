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
    it("sell requires token approval", async () => {
      
    })

    it("sell requires at least one token", async () => {
      
    })

    it("sell locks Pack", async () => {
      
    })

    it("sell creates listing", async () => {

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