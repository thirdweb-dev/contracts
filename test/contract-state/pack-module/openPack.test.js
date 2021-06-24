const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");
const [pairs, forkFrom] = require('../../../utils/utils.js');

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("Testing the 'openPack' flow.", function() {
  // Let the test run for 3 minutes max
  this.timeout(180000);

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
  const forkBlock = 12635536;

  // Pack ERC1155 params
  const numOfPacks = 50;
  const numOfrewardsPerPack = 10;

  const packURIs = [];
  const rewardURIs = [];
  const rewardMaxSupplies = [];

  let packIds = []

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

    // Register `PackERC1155` as a module in `PackControl`
    packERC1155ModuleName = await packControl.PACK_ERC1155();
    await packControl.connect(protocolAdmin).initPackERC1155(packERC1155.address);
    
    // Deploy RNG contract
    const RNG_Factory = await ethers.getContractFactory("DexRNG");
    rng = await RNG_Factory.deploy();

    // Register RNG as a module in `PackControl`
    rngModuleName = await packERC1155.RNG_MODULE_NAME();
    await packControl.connect(protocolAdmin).addModule(rngModuleName, rng.address);

    // Set up RNG
    for(let pairInfo of pairs) {
      await rng.addPair(pairInfo.pair);
    }

    // Set up Pack ERC1155 params
    for(let i = 0; i < numOfPacks; i++) {
      if(i < numOfrewardsPerPack) {
        rewardURIs.push(`This is a dummy reward URI ${Math.floor(Math.random() * 100)}`)
        rewardMaxSupplies.push(Math.floor(Math.random() * 100));
      }

      packURIs.push(`This is a dummy pack URI ${Math.floor(Math.random() * 100)}`)
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
    
    // `createPack`
    for (let packURI of packURIs) {
      const packId = parseInt((await packERC1155.currentTokenId()).toString());
      packIds.push(packId);

      await packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);
    }
  })

  describe("State changes in PackHandler.sol", () => {

    describe("Revert", () => {

      it("Should revert if caller has zero balance of the pack", async () => {        
        const packId = packIds[Math.floor(Math.random() * packIds.length)];
      
        const endUserPackBalance = parseInt((await packERC1155.balanceOf(endUser.address, packId)).toString());
        expect(endUserPackBalance).to.equal(0);

        await expect(packHandler.connect(endUser).openPack(packId))
          .to.be.revertedWith("Sender owns no packs of the given packId.");
      })      
    })

    describe("Events", () => {

      beforeEach(async () => {
        
        // End user approves PackHandler to move all pack and reward tokens.
        await packERC1155.connect(endUser).setApprovalForAll(packHandler.address, true);

        // Airdrop pack tokens to endUser.
        for (let id of packIds) {          
          await packERC1155.connect(creator).safeTransferFrom(
            creator.address,
            endUser.address,
            id,
            1,
            ethers.utils.toUtf8Bytes("")
          );
        }        
      })

      it("Should emit 'RewardDistributed'", async () => {        
        for(let id of packIds) {
          await expect(packHandler.connect(endUser).openPack(id))
            .to.emit(packHandler, "RewardDistributed");
        }
      })

      it("Should emit 'PackOpened'", async () => {        
        for(let id of packIds) {
          await expect(packHandler.connect(endUser).openPack(id))
            .to.emit(packHandler, "PackOpened")
            .withArgs(endUser.address, id);
        }
      })
    })

    describe("Storage", () => {
      before(async () => {
        
        // End user approves PackHandler to move all pack and reward tokens.
        await packERC1155.connect(endUser).setApprovalForAll(packHandler.address, true);

        // Airdrop pack tokens to endUser.
        for (let id of packIds) {          
          await packERC1155.connect(creator).safeTransferFrom(
            creator.address,
            endUser.address,
            id,
            1,
            ethers.utils.toUtf8Bytes("")
          );
        }        
      })

      it("Should update the `rarityUnit` of the pack token in the tokens mapping", async () => {        
        for(let id of packIds) {
          const packBeforerOpen = await packHandler.tokens(id);
          const rarityUnitBeforeOpen = parseInt((packBeforerOpen.rarityUnit).toString())
          
          await packHandler.connect(endUser).openPack(id);

          const packAfterOpen = await packHandler.tokens(id);
          const rarityUnitAfterOpen = parseInt((packAfterOpen.rarityUnit).toString());

          expect(rarityUnitBeforeOpen - rarityUnitAfterOpen).to.equal(1);
        }
      })
    })
  })
})