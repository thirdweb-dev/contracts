const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

chai.use(solidity)
const { expect } = chai;

describe("Pack", () => {
  let pack;
  let sender;

  beforeEach(async () => {
    const [owner] = await ethers.getSigners();
    sender = owner;

    const Pack = await ethers.getContractFactory("Pack", sender);
    pack = await Pack.deploy();
  })

  it("createPack emits PackCreated", async () => {
    expect(await pack.createPack("URI", 100))
      .to
      .emit(pack, "PackCreated")
      .withArgs(sender.address, 0, "URI", 100);
  })
})