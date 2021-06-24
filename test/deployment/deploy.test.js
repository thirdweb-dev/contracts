const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("Deploying the pack protocol system.", () => {

  // Pack Protocol contracts.
  let packControl
  let packERC1155
  let packHandler;
  let packMarket
  let rng

  // Module names
  let packERC1155ModuleName
  let packHandlerModuleName
  let packMarketModuleName
  let rngModuleName

  // Signers
  let protocolAdmin;
  let creator;
  let endUser;

  before(async () => {

    // Get signers
    [protocolAdmin, creator, endUser] = await ethers.getSigners();
    
    // 1. Deploy control center `PackControl.sol`
    const PackControl_Factory = await ethers.getContractFactory("PackControl");
    packControl = await PackControl_Factory.deploy();
    
    // 2.A. Deploy core module `PackERC1155.sol`
    const PackERC1155_Factory = await ethers.getContractFactory("PackERC1155");
    packERC1155 = await PackERC1155_Factory.deploy(packControl.address);

    // 2.B. Register `PackERC1155` as a module in `PackControl`
    packERC1155ModuleName = await packControl.PACK_ERC1155();
    await packControl.connect(protocolAdmin).initPackERC1155(packERC1155.address);
    
    // 3.A. Deploy module `Pack.sol`
    const PackHandler_Factory = await ethers.getContractFactory("Pack");
    packHandler = await PackHandler_Factory.deploy(packERC1155.address);

    // 3.B. Register `Pack` as a module in `PackControl`
    packHandlerModuleName = "PACK_HANDLER";
    await packControl.connect(protocolAdmin).addModule(packHandlerModuleName, packHandler.address);
    
    // 4.A. Deploy module `PackMarket.sol`
    const PackMarket_Factory = await ethers.getContractFactory("PackMarket");
    packMarket = await PackMarket_Factory.deploy(packControl.address);

    // 4.B. Register `PackMarket` as a module in `PackControl`
    packMarketModuleName = "PACK_MARKET";
    await packControl.connect(protocolAdmin).addModule(packMarketModuleName, packMarket.address);
    
    // 5.A. Deploy RNG contract
    const RNG_Factory = await ethers.getContractFactory("DexRNG");
    rng = await RNG_Factory.deploy();

    // 5.B. Register RNG as a module in `PackControl`
    rngModuleName = await packERC1155.RNG_MODULE_NAME();
    await packControl.connect(protocolAdmin).addModule(rngModuleName, rng.address);
  })

  it("Should return the correct addresses of the pack protocol modules.", async () => {
    expect(await packControl.getModule(packERC1155ModuleName)).to.equal(packERC1155.address);
    expect(await packControl.getModule(packHandlerModuleName)).to.equal(packHandler.address);
    expect(await packControl.getModule(packMarketModuleName)).to.equal(packMarket.address);
    expect(await packControl.getModule(rngModuleName)).to.equal(rng.address);
  })
})