const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("Pack", () => {
  let pack;
  let owner;
  let buyer;

  const uri = "100";
  const supply = 100;

  const rewardUri = "200";
  const rewardSupply = 200;

  before(async () => {
    signers = await ethers.getSigners();
    [owner, buyer] = signers;
  });

  // Get message sender and pack interface before each test
  beforeEach(async () => {
    const Pack = await ethers.getContractFactory("Pack", vrfCoordinator, linkToken, keyHash);
    pack = await Pack.deploy();
  });

  // createPack(string memory tokenUri, uint256 maxSupply) external returns (uint256 tokenId)
  describe("createPack", async () => {
    it("createPack creates pack Token", async () => {
      const { value: tokenId } = await pack.createPack(uri, supply, [rewardUri], [rewardSupply]);
      expect(tokenId).to.equal(0);

      const token = await pack.tokens(tokenId);
      expect(token.uri).to.equal(uri);
      expect(token.currentSupply).to.equal(supply);
      expect(token.maxSupply).to.equal(supply);
      console.log("token", token);
    });

    it("createPack gives Pack to sender", async () => {
      const { value: tokenId } = await pack.createPack(uri, supply, [rewardUri], [rewardSupply]);

      const createdPack = await pack.packs(tokenId);
      expect(createdPack.creator).to.equal(owner.address);
      expect(createdPack.numRewardOnOpen).to.equal(1);
      expect(createdPack.rarityDenominator).to.equal(0);
    });

    it("createPack emits PackCreated", async () => {
      expect(await pack.createPack(uri, supply, [rewardUri], [rewardSupply]))
        .to.emit(pack, "PackCreated")
        .withArgs(owner.address, 0, uri, supply);
    });
  });

  // openPack(uint256 packId) external
  describe("openPack", async () => {
    beforeEach(async () => {
      await pack.createPack(uri, supply, [rewardUri], [rewardSupply]);
    });

    it("openPack sender must own pack", async () => {
      try {
        await pack.connect(buyer).openPack(0);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("insufficient pack");
      }
    });

    it("openPack destroys Pack", async () => {
      expect(await pack.balanceOf(owner.address, 0)).to.equal(100);
      await pack.openPack(0);
      expect(await pack.balanceOf(owner.address, 0)).to.equal(99);
    });

    it("openPack assigns Token", async () => {
      expect(await pack.balanceOf(owner.address, 1)).to.equal(0);
      await pack.openPack(0);
      expect(await pack.balanceOf(owner.address, 1)).to.equal(1);
    });

    it("openPack reduces rarityDenominator", async () => {
      const { rarityDenominator: prePackRarity } = await pack.packs(tokenId);
      await pack.openPack(tokenId);
      const { rarityDenominator: postPackRarity } = await pack.packs(tokenId);
      expect(prePackRarity.toNumber() - 1).to.equals(postPackRarity.toNumber());
    });

    it("openPack emits PackOpened", async () => {
      expect(await pack.openPack(0))
        .to.emit(pack, "PackOpened")
        .withArgs(owner.address, 0, [1]);
    });
  });
});
