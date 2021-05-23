const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity)
const { expect } = chai;

describe("Pack", () => {
  let pack;
  let owner;
  let buyer;

  const uri = "100";
  const supply = 100;

  before(async () => {
    signers = await ethers.getSigners();
    [owner, buyer] = signers;
  })

  // Get message sender and pack interface before each test
  beforeEach(async () => {
    const Pack = await ethers.getContractFactory("Pack", owner);
    pack = await Pack.deploy();
  })

  // createPack(string memory tokenUri, uint256 maxSupply) external returns (uint256 tokenId)
  describe("createPack", async () => {
    it("createPack creates pack Token", async () => {
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
      expect(createdPack.creator).to.equal(owner.address);
      expect(createdPack.owner).to.equal(owner.address);
      expect(createdPack.numRewardOnOpen).to.equal(1);
    })

    it("createPack emits PackCreated", async () => {
      expect(await pack.createPack(uri, supply))
        .to
        .emit(pack, "PackCreated")
        .withArgs(owner.address, 0, uri, supply);
    })
  })

  // addRewards(uint256 packId, uint256[] memory tokenMaxSupplies, string[] memory tokenUris) external
  describe("addRewards", async () => {
    beforeEach(async () => {
      await pack.createPack(uri, supply);
    })

    it("addRewards only works for Pack owner", async () => {
      try {
        await pack.connect(buyer).addRewards(0, [uri], [100]);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("revert not the pack owner")
      }
    })

    it("addRewards only works for unlocked Packs", async () => {
      try {
        await pack.lockReward(0);
        await pack.addRewards(0, [uri], [100]);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("reward is locked");
      }
    })

    it("addRewards tokenMaxSupplies must be same length as tokenUris", async () => {
      try {
        await pack.addRewards(0, [uri, uri], [100]);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("must be same length");
      }
    })

    it("addRewards emits PackRewardsAdded", async () => {
      expect(await pack.addRewards(0, [uri], [100]))
        .to
        .emit(pack, "PackRewardsAdded")
        .withArgs(owner.address, 0, [1], ['']);
    })
  })

  // openPack(uint256 packId) external
  describe("openPack", async () => {
    beforeEach(async () => {
      await pack.createPack(uri, supply);
    })

    it("openPack sender must own pack", async () => {
      try {
        await pack.addRewards(0, [uri], [100])
        await pack.lockReward(0);
        await pack.connect(buyer).openPack(0);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("insufficient pack");
      }
    })

    it("openPack rewards must be locked", async () => {
      try {
        await pack.addRewards(0, [uri], [100])
        await pack.openPack(0);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("rewards not locked yet");
      }
    })

    it("openPack must be at least one reward", async () => {
      try {
        await pack.lockReward(0);
        await pack.openPack(0);
        expect(false).to.equal(true);
      } catch (err) {
        expect(err.message).to.contain("no rewards available");
      }
    })

    it("openPack destroys Pack", async () => {
      expect(await pack.balanceOf(owner.address, 0)).to.equal(100);
      await pack.addRewards(0, [uri], [100])
      await pack.lockReward(0);
      await pack.openPack(0);
      expect(await pack.balanceOf(owner.address, 0)).to.equal(99);
    })

    it("openPack assigns Token", async () => {
      expect(await pack.balanceOf(owner.address, 1)).to.equal(0);
      await pack.addRewards(0, [uri], [100])
      await pack.lockReward(0);
      await pack.openPack(0);
      expect(await pack.balanceOf(owner.address, 1)).to.equal(1);
    })

    it("openPack emits PackOpened", async () => {
      await pack.addRewards(0, [uri], [100])
      await pack.lockReward(0);
      expect(await pack.openPack(0))
        .to
        .emit(pack, "PackOpened")
        .withArgs(owner.address, 0, [1]);
    })
  })
})