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

  const rewardUris = ["200"];
  const rewardSupplies = [200];
  const rewardSupplyCount = 200;

  before(async () => {
    signers = await ethers.getSigners();
    [owner, buyer] = signers;
  });

  // Get message sender and pack interface before each test
  beforeEach(async () => {
    const Pack = await ethers.getContractFactory("Pack", owner);
    pack = await Pack.deploy(
      process.env.CHAINLINK_VRF_COORDINATOR,
      process.env.CHAINLINK_LINK_TOKEN,
      process.env.CHAINLINK_KEY_HASH,
    );
  });

  // createPack(string memory tokenUri, uint256 maxSupply) external returns (uint256 tokenId)
  describe("createPack", async () => {
    it("createPack creates pack Token", async () => {
      const { value: tokenId } = await pack.createPack(uri, rewardUris, rewardSupplies);
      expect(tokenId).to.equal(0);

      const token = await pack.tokens(tokenId);
      expect(token.uri).to.equal(uri);
    });

    it("createPack gives Pack to sender", async () => {
      const { value: tokenId } = await pack.createPack(uri, rewardUris, rewardSupplies);

      const createdPack = await pack.tokens(tokenId);
      expect(createdPack.creator).to.equal(owner.address);
    });

    it("createPack rarityUnit == maxSupply", async () => {
      const { value: tokenId } = await pack.createPack(uri, rewardUris, rewardSupplies);

      const createdPack = await pack.tokens(tokenId);
      expect(createdPack.rarityUnit).to.equal(rewardSupplyCount);
    });

    it("createPack emits PackCreated", async () => {
      expect(await pack.createPack(uri, rewardUris, rewardSupplies))
        .to.emit(pack, "PackCreated")
        .withArgs(owner.address, 0, uri, rewardSupplyCount);
    });
  });

  // openPack(uint256 packId) external
  describe("openPack", async () => {
    beforeEach(async () => {
      await pack.createPack(uri, rewardUris, rewardSupplies);
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
