const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("Contract deployment and inital setup", () => {
  let packToken;
  let packRNG;

  // Get message sender and pack interface before each test
  beforeEach(async () => {
    const PackTokenFactory = await ethers.getContractFactory("Pack");
    packToken = await PackTokenFactory.deploy();

    const PackRNGFactory = await ethers.getContractFactory("PackBlockRNG");
    packRNG = await PackRNGFactory.deploy(packToken.address);
  });

  it("Should initialize currentTokenId with value 0", async () => {
    const currentTokenId = await packToken._currentTokenId();
    expect(currentTokenId).to.equal(0);
  })

  it("Should emit RNGSet event upon initializing the RNG", async () => {
    await expect(packToken.setRNG(packRNG.address))
      .to.emit(packToken, "RNGSet")
      .withArgs(packRNG.address);
  })
})