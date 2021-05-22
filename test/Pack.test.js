const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity)
const { expect } = chai;

describe("Pack", () => {
  let pack;
  let Pack;
  let sender;

  // Get message sender and pack interface before each test
  beforeEach(async () => {
    const [owner] = await ethers.getSigners();
    sender = owner;

    const Pack = await ethers.getContractFactory("Pack", sender);
    pack = await Pack.deploy();
  })

  // createPack(string memory tokenUri, uint256 maxSupply) external returns (uint256 tokenId)
  describe("createPack", async () => {
    it("createPack creates Token", async () => {
      const { value: tokenId } = await pack.createPack("URI", 100);
      expect(tokenId).to.equal(0);

      const token = await pack.tokens(tokenId);
      expect(token.uri).to.equal("URI");
      expect(token.currentSupply).to.equal(0);
      expect(token.maxSupply).to.equal(100);
    })

    it("createPack emits PackCreated", async () => {
      expect(await pack.createPack("URI", 100))
        .to
        .emit(pack, "PackCreated")
        .withArgs(sender.address, 0, "URI", 100);
    })
  })
})