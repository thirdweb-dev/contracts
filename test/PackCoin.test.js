const chai = require("chai")
const { ethers } = require("hardhat")
const { solidity } = require("ethereum-waffle")

chai.use(solidity)
const { expect } = chai

describe("PackCoin", () => {
  let packCoin

  beforeEach(async () => {
    const PackCoin = await ethers.getContractFactory("PackCoin")
    packCoin = await PackCoin.deploy()
  })
})