const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("createPack", () => {
  let packToken;
  let packRNG;

  let deployer;
  let creator;
  let fan;
  
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
  });

  describe("Revert cases", () => {

    it("Should revert if the number of URIs and maxSupplies is not the same", async () => {
      await expect(packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies.slice(1)))
        .to.be.revertedWith("Must provide the same amount of maxSupplies and URIs.")
    })

    it("Should revert if there are no reward URIs supplied", async () => {
      await expect(packToken.connect(creator).createPack(packURI, [], []))
        .to.be.revertedWith("Cannot create a pack with no rewards.")
    })
  })

  describe("Events", () => {
    it("Should emit PackCreated event upon pack creation", async () => {
      const expectedPackId = parseInt((await packToken._currentTokenId()).toString());
      const sumOfMaxSupplies = rewardMaxSupplies.reduce((a, b) => (a+b), 0);

      await expect(packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies))
        .to.emit(packToken, "PackCreated")
        .withArgs(creator.address, expectedPackId, packURI, sumOfMaxSupplies);
    })

    it("Should emit RewardsAdded event upon pack creation", async () => {
      const expectedPackId = await packToken._currentTokenId()
      const expectedRewardIds = [];
      
      let expectedRewardId = parseInt((expectedPackId).toString()) + 1
      for(let i = 0; i < rewardURIs.length; i++) {
        expectedRewardIds.push(expectedRewardId)
        expectedRewardId++;
      }

      await expect(packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies))
        .to.emit(packToken, "RewardsAdded")
        .withArgs(expectedPackId, expectedRewardIds, rewardURIs, rewardMaxSupplies);
    })
  })

  describe("ERC1155 balances", () => {
    it("Should mint the maxSupply of pack to the creator", async () => {
      const expectedPackId = await packToken._currentTokenId()
      expect(await packToken.balanceOf(creator.address, expectedPackId)).to.equal(0);

      const sumOfMaxSupplies = rewardMaxSupplies.reduce((a, b) => (a+b), 0);
      const { value: tokenId } = await packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);

      expect(expectedPackId).to.equal(tokenId)
      expect(await packToken.balanceOf(creator.address, tokenId)).to.equal(sumOfMaxSupplies);
    })
  })

  describe("Contract state changes", async () => {
    it("Should update the 'tokens' mapping with the created pack", async () => {
      const sumOfMaxSupplies = rewardMaxSupplies.reduce((a, b) => (a+b), 0);

      const { value: tokenId } = await packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);
      const createdPack = await packToken.tokens(tokenId)

      expect(createdPack.creator).to.equal(creator.address);
      expect(createdPack.uri).to.equal(packURI);
      expect(createdPack.rarityUnit).to.equal(sumOfMaxSupplies);
      expect(createdPack.maxSupply).to.equal(sumOfMaxSupplies);
      expect(createdPack.tokenType).to.equal(0); // uint(TokenType.Pack) == 0
    })

    it("Should update the `tokens` mapping with the created rewards", async () => {
      const { value: tokenId } = await packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);
      const parsedTokenId = parseInt((tokenId).toString());

      let expectedRewardId = parsedTokenId + 1
      for(let i = 0; i < rewardURIs.length; i++) {
        
        const reward = await packToken.tokens(expectedRewardId)

        expect(reward.creator).to.equal(creator.address);
        expect(reward.uri).to.equal(rewardURIs[i]);
        expect(reward.rarityUnit).to.equal(rewardMaxSupplies[i]);
        expect(reward.maxSupply).to.equal(rewardMaxSupplies[i]);
        expect(reward.tokenType).to.equal(1); // uint(TokenType.Reward) == 1

        expectedRewardId++
      }
    })

    it("Should update the 'rewardsInPack' mapping with the created reward token IDs", async () => {
      const expectedPackId = await packToken._currentTokenId()
      const expectedRewardIds = [];
      
      let expectedRewardId = parseInt((expectedPackId).toString()) + 1
      for(let i = 0; i < rewardURIs.length; i++) {
        expectedRewardIds.push(expectedRewardId)
        expectedRewardId++;
      }
      const { value: tokenId } = await packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);

      for(let i = 0; i < expectedRewardIds.length; i++) {
        const rewardId = await packToken.rewardsInPack(tokenId, i);
        expect(rewardId).to.equal(expectedRewardIds[i])
      }
    })

    it("Should update the 'circulatingSupply' mapping with the pack max supply", async () => {
      const sumOfMaxSupplies = rewardMaxSupplies.reduce((a, b) => (a+b), 0);
      const { value: tokenId } = await packToken.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);

      const packCirculatingSupply = await packToken.circulatingSupply(tokenId);
      expect(packCirculatingSupply).to.equal(sumOfMaxSupplies);
    })
  })
})