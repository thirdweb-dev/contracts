const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity)
const { expect } = chai;

describe("Pack", () => {
  let pack;
  let sender;
  let signers;

  const uri = "URI";
  const supply = 100;

  before(async () => {
    signers = await ethers.getSigners();
    [sender] = signers;
  })

  // Get message sender and pack interface before each test
  beforeEach(async () => {
    const Pack = await ethers.getContractFactory("Pack", sender);
    pack = await Pack.deploy();
  })

  // createPack(string memory tokenUri, uint256 maxSupply) external returns (uint256 tokenId)
  describe("createPack", async () => {
    it("createPack creates Token", async () => {
      const { value: tokenId } = await pack.createPack(uri, supply);
      expect(tokenId).to.equal(0);

      const token = await pack.tokens(tokenId);
      expect(token.uri).to.equal(uri);
      expect(token.currentSupply).to.equal(supply);
      expect(token.maxSupply).to.equal(supply);
    })

    it("createPack gives Pack to sender", async () => {
      const { value: tokenId } = await pack.createPack(uri, supply);

      const createdPack = await pack.packs(tokenId);
      expect(createdPack.isRewardLocked).to.equal(false);
      expect(createdPack.creator).to.equal(sender.address);
      expect(createdPack.owner).to.equal(sender.address);
      expect(createdPack.numRewardOnOpen).to.equal(1);
    })

    it("createPack emits PackCreated", async () => {
      expect(await pack.createPack(uri, supply))
        .to
        .emit(pack, "PackCreated")
        .withArgs(sender.address, 0, uri, supply);
    })
  })

  // openPack(uint256 packId) external
  describe("openPack", async () => {
    beforeEach(async () => {
      await pack.createPack(uri, supply);
    })

    it("openPack sender must own pack", async () => {
      
    })

    it("openPack rewards must be locked", async () => {
      
    })

    it("openPack destroys Pack", async () => {
      
    })

    it("openPack assigns Token", async () => {

    })

    it("openPack emits PackOpened", async () => {

    })
  })

  // addRewards(uint256 packId, uint256[] memory tokenMaxSupplies, string[] memory tokenUris) external
  describe("addRewards", async () => {
    it("addRewards only works for Pack owner", async () => {

    })

    it("addRewards only works for unlocked Packs", async () => {

    })

    it("addRewards tokenMaxSupplies must be same length as tokenUris", async () => {

    })

    it("addRewards emits PackRewardsAdded", async () => {

    })
  })
})