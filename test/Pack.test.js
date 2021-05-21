const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

chai.use(solidity);
const { expect } = chai;

describe("Pack", () => {
  let pack;

  beforeEach(async () => {
    const Pack = await ethers.getContractFactory("Pack");
    pack = await Pack.deploy();
  })
})