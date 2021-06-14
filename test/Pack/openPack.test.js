const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("openPack", () => {
  let packToken;
  let packRNG;

  let deployer;
  let creator;
  let fan;

  let packId;
  
  const packURI = 'This is a dummy pack URI';
  const rewardURIs = [];
  const rewardMaxSupplies = [];

  before(async () => {
    signers = await ethers.getSigners();
    [deployer, creator, fan] = signers;
  });

  // Get message sender and pack interface before each test
  beforeEach(async () => {
    const PackTokenFactory = await ethers.getContractFactory("Pack");
    packToken = await PackTokenFactory.deploy();

    const PackRNGFactory = await ethers.getContractFactory("PackBlockRNG");
    packRNG = await PackRNGFactory.deploy(packToken.address);

    await packToken.setRNG(packRNG.address)

    for(let i = 0; i < 5; i++) {
      rewardURIs.push(`This is a dummy reward URI no. ${i}`);
      rewardMaxSupplies.push(
        Math.floor(Math.random() * 100)
      );
    }

    const { value: tokenId } = await packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);
    packId = tokenId;

    // Airdrop to `fan`
    await packToken.connect(creator).safeTransferFrom(creator.address, fan.address, packId, 1, ethers.utils.randomBytes(0));
  });

  describe("Revert cases", () => {
    it("Should revert if the caller does not own pack tokens", async () => {
      await expect(packToken.openPack(packId))
        .to.be.revertedWith("Sender owns no packs of the given packId.");
    })
  })

  describe("Events", () => {

    it("Should emit PackOpened in Pack.sol upon calling openPack", async () => {
      const expectedReqId = (parseInt(await packRNG.requestCount()).toString()) + 1;

      expect(await packToken.connect(fan).openPack(packId))
        .to.emit(packToken, "PackOpened")
        .withArgs(fan.address, packId, expectedReqId)
    })

    it("Should emit RandomNumberRequested in PackBlockRNG.sol upon a random number request", async () => {
      const expectedReqId = (parseInt(await packRNG.requestCount()).toString()) + 1;

      expect(await packToken.connect(fan).openPack(packId))
        .to.emit(packRNG, "RandomNumberRequested")
        .withArgs(expectedReqId, packToken.address)
    })
  })
})