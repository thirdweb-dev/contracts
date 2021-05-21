const chai = require("chai")
const { ethers } = require("hardhat")
const { solidity } = require("ethereum-waffle")

chai.use(solidity)
const { expect } = chai

describe("PackMarket", () => {
  let packMarket

  beforeEach(async () => {
    const PackMarket = await ethers.getContractFactory("PackMarket")
    packMarket = await PackMarket.deploy()
  })
})