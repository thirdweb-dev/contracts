const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

chai.use(solidity);
const { expect } = chai;

describe("PackMarket", async () => {
  let packMarket;
  let owner;
  let buyer;

  before(async () => {
    signers = await ethers.getSigners();
    [owner, buyer] = signers;
  })

  beforeEach(async () => {
    const PackMarket = await ethers.getContractFactory("PackMarket", owner);
    packMarket = await PackMarket.deploy();
  })

  describe("setPackToken", async () => {
    it("setPackToken only owner can change Pack", async () => {
      
    })

    it("setPackToken emits PackTokenChange", async () => {

    })
  })

  describe("sell", async () => {
    it("sell requires token approval", async () => {
      
    })

    it("sell requires at least one token", async () => {
      
    })

    it("sell locks Pack", async () => {
      
    })

    it("sell creates listing", async () => {

    })

    it("sell emits PackListed", async () => {

    })
  })

  describe("buy", async () => {
    it("buy successfully transfers Pack", async () => {
      
    })

    it("buy emits PackSold", async () => {

    })
  })
})