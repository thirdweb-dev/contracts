const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");
const [pairs, forkFrom] = require('../../utils/utils.js');

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("Checks gas consumed by 'createPack'", () => {
  // Pack Protocol contracts.
  let packControl
  let packERC1155
  let packHandler;
  let rng
  // Module names
  let packERC1155ModuleName
  let packHandlerModuleName
  let rngModuleName

  // Signers
  let protocolAdmin;
  let creator;
  let endUser;

  // Mainnet fork params
  const forkBlock = 12724513;

  // Pack ERC1155 params
  const numOfrewardsPerPack = 10;

  const packURI = "This is a dummy pack URI";
  const rewardURIs = [];
  const rewardMaxSupplies = [];

  before(async () => {

    // Fork Mainnet
    await forkFrom(forkBlock);

    // Get signers
    [protocolAdmin, creator, endUser] = await ethers.getSigners();
    
    // Deploy control center `PackControl.sol`
    const PackControl_Factory = await ethers.getContractFactory("PackControl");
    packControl = await PackControl_Factory.deploy();
    
    // Deploy core module `PackERC1155.sol`
    const PackERC1155_Factory = await ethers.getContractFactory("PackERC1155");
    packERC1155 = await PackERC1155_Factory.deploy(packControl.address);

    // Deploy RNG contract
    const RNG_Factory = await ethers.getContractFactory("DexRNG");
    rng = await RNG_Factory.deploy();

    // Init pack protocol
    packERC1155ModuleName = await packControl.PACK_ERC1155();
    rngModuleName = await packControl.PACK_RNG();

    await packControl.connect(protocolAdmin).initPackProtocol(packERC1155.address, rng.address);

    // Set up RNG
    for(let pairInfo of pairs) {
      await rng.addPair(pairInfo.pair);
    }

    // Deploy module `Pack.sol`
    const PackHandler_Factory = await ethers.getContractFactory("PackHandler");
    packHandler = await PackHandler_Factory.deploy(packERC1155.address);

    // Register `Pack` as a module in `PackControl`
    packHandlerModuleName = "PACK_HANDLER";
    await packControl.connect(protocolAdmin).addModule(packHandlerModuleName, packHandler.address);

    // Grant MINTER_ROLE to `PackHandler`
    const MINTER_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    )
    await packControl.connect(protocolAdmin).grantRoleERC1155(MINTER_ROLE, packHandler.address);
  })

  it("Should print the gas consumed for creating a pack with 3 rewards", async () => {

    // Set up Pack ERC1155 params
    for(let i = 0; i < numOfrewardsPerPack; i++) {
      rewardURIs.push(`This is a dummy reward URI ${Math.floor(Math.random() * 100)}`)
      rewardMaxSupplies.push(Math.floor(Math.random() * 100));

      console.log(`Creating a pack with ${rewardURIs.length} rewards.`)
      const estimate = await packHandler.estimateGas.createPack(packURI, rewardURIs, rewardMaxSupplies);
      const parsedEstimate = parseInt((estimate).toString())
      console.log("Estimated gas consumed: ", parsedEstimate, "\n");
    }
  })
})

// Current: 1 reward: 430k, 3 rewards: 720k, 5 rewards: 1 mil.