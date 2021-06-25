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

    // Set up Pack ERC1155 params
    for(let i = 0; i < numOfPacks; i++) {
      if(i < numOfrewardsPerPack) {
        rewardURIs.push(`This is a dummy reward URI ${Math.floor(Math.random() * 100)}`)
        rewardMaxSupplies.push(10 + Math.floor(Math.random() * 100));
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

  describe("State changes in PackERC1155.sol", () => {

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

      it("Should emit 'TokensBurned'", async () => {
        for(let id of packIds) {

          
          await expect(packHandler.connect(endUser).openPack(id))
            .to.emit(packERC1155, "TokensBurned")
            .withArgs(endUser.address, [id], [1]);
        }
      })
    })

    describe("Storage", () => {
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

      it("Should update the circulating supply of the pack token burned", async () => {
        for(let id of packIds) {
          const tokenBeforeBurn = await packERC1155.tokens(id);
          const supplyBeforeBurn = parseInt((tokenBeforeBurn.circulatingSupply).toString());

          await packHandler.connect(endUser).openPack(id)

          const tokenAfterBurn = await packERC1155.tokens(id);
          const supplyAfterBurn = parseInt((tokenAfterBurn.circulatingSupply).toString());

          expect(supplyBeforeBurn - supplyAfterBurn).to.equal(1);
        }
      })

      it("Should update the tokens mapping with the created reward token", async () => {
        for (let i = 1; i < packIds.length; i++) {
          const id = packIds[i-1]
          const nextPackId = packIds[i];   
          
          const supplyBefore = {};

          for(let j = id + 1; j < nextPackId; j++) {            
            const reward = await packERC1155.tokens(j)

            supplyBefore[j] = reward.circulatingSupply;
          }

          await packHandler.connect(endUser).openPack(id)

          for(let j = id + 1; j < nextPackId; j++) {
            const reward = await packERC1155.tokens(j)
            expect(reward.circulatingSupply).to.be.gte(supplyBefore[j])

            if(reward.circulatingSupply > supplyBefore[j]) {
              expect(reward.circulatingSupply - supplyBefore[j]).to.equal(1)
            }

            if(reward.tokenType == 1) {
              expect(reward.creator).to.equal(creator.address);
            }
          }            
        }
      })
    })

    describe("ERC1155 balances", () => {
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

      it("Should decrement the pack token balance of the end user by 1", async () => {
        for(let id of packIds) {
          const endUserBalBeforeOpen = parseInt((await packERC1155.balanceOf(endUser.address, id)).toString());
          await packHandler.connect(endUser).openPack(id);
          const endUserBalAfterOpen = parseInt((await packERC1155.balanceOf(endUser.address, id)).toString());

          expect(endUserBalBeforeOpen - endUserBalAfterOpen).to.equal(1);
        }      
      })

      it("Should increment the end user balance of the created reward token by 1", async () => {
        for (let i = 1; i < packIds.length; i++) {
          const id = packIds[i-1]
          const nextPackId = packIds[i];

          const balBeforeOpen = {};

          for(let j = id + 1; j < nextPackId; j++) {            
            const bal = parseInt((await packERC1155.balanceOf(endUser.address, j)).toString());

            balBeforeOpen[j] = bal;
          }

          await packHandler.connect(endUser).openPack(id)

          for(let j = id + 1; j < nextPackId; j++) {            
            const bal = parseInt((await packERC1155.balanceOf(endUser.address, j)).toString());

            expect(bal).to.be.gte(balBeforeOpen[j]);

            if(bal > balBeforeOpen[j]) {
              expect(bal - balBeforeOpen[j]).to.equal(1);
            }            
          }
        }
      })
    })
    
  })
})