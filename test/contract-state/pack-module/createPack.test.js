const chai = require("chai");
const { ethers } = require("hardhat");
const { solidity } = require("ethereum-waffle");
const [pairs, forkFrom] = require('../../../utils/utils.js');

// Use chai solidity plugin
chai.use(solidity);
const { expect } = chai;

describe("Deploying the pack protocol system.", function() {
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

    beforeEach(async () => {
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
  })

  describe("State changes in PackHandler.sol", () => {

    describe("Revert", async () => {
      it("Should revert if number of rewards and max supplies provided aren't equal", async () => {
        await expect(packHandler.connect(creator).createPack(packURIs[0], rewardURIs, rewardMaxSupplies.slice(-1)))
          .to.be.revertedWith("Must provide the same amount of maxSupplies and URIs.");
      })
    
      it("Should revert if no rewards are provided", async () => {
        await expect(packHandler.connect(creator).createPack(packURIs[0], [], []))
          .to.be.revertedWith("Cannot create a pack with no rewards.");
      })
    })

    describe("Events", async () => {
      
      it("Should emit 'PackCreated' for every new pack created.", async () => {
        for(let packURI of packURIs) {

          const expectedPackId = parseInt((await packERC1155.currentTokenId()).toString());
          const packMaxSupply = rewardMaxSupplies.reduce((a,b) => a+b);

          await expect(packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies))
            .to.emit(packHandler, "PackCreated")
            .withArgs(creator.address, expectedPackId, packURI, packMaxSupply);
        }
      })

      it("Should emit 'RewardsAdded' for every new pack created", async () => {
        for(let packURI of packURIs) {

          const expectedPackId = parseInt((await packERC1155.currentTokenId()).toString());
          const expectedRewardIds = []
          for(let i = 1; i <= numOfrewardsPerPack.length; i++) {
            expectedRewardIds.push(expectedPackId + i);
          }

          await expect(packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies))
            .to.emit(packHandler, "RewardsAdded")
            .withArgs(expectedPackId, expectedRewardIds, rewardURIs, rewardMaxSupplies);
        }
      })
    })

    describe("Storage", async () => {

      it("Should update the tokens mapping with the right pack token data", async () => {
        for(let packURI of packURIs) {

          const expectedPackId = parseInt((await packERC1155.currentTokenId()).toString());
          const packMaxSupply = rewardMaxSupplies.reduce((a,b) => a+b);

          await packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);

          const createdPack = await packHandler.tokens(expectedPackId);
          
          expect(createdPack.creator).to.equal(creator.address);
          expect(createdPack.uri).to.equal(packURI);
          expect(createdPack.rarityUnit).to.equal(packMaxSupply);
          expect(createdPack.maxSupply).to.equal(packMaxSupply);
          expect(createdPack.tokenType).to.equal(0); // uint(TokenType.Pack) == 0
        }
      })

      it("Should update the tokens mapping with the right reward token data", async () => {
        for(let packURI of packURIs) {

          const expectedPackId = parseInt((await packERC1155.currentTokenId()).toString());
          const expectedRewardIds = []
          for(let i = 1; i <= numOfrewardsPerPack.length; i++) {
            expectedRewardIds.push(expectedPackId + i);
          }

          await packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);

          for(let j = 0; j < expectedRewardIds.length; j++) {
            const id = expectedRewardIds[j];
            const uri = rewardURIs[j];
            const supply = rewardMaxSupplies[j];

            const createdReward = await packHandler.tokens(id);

            expect(createdReward.creator).to.equal(creator.address);
            expect(createdReward.uri).to.equal(uri);
            expect(createdReward.rarityUnit).to.equal(supply);
            expect(createdReward.maxSupply).to.equal(supply);
            expect(createdReward.tokenType).to.equal(1); // uint(TokenType.Reward) == 1
          }
        }
      })

      it("Should update the rewardsInPack mapping with the right reward IDs", async () => {
        for(let packURI of packURIs) {

          const expectedPackId = parseInt((await packERC1155.currentTokenId()).toString());
          const expectedRewardIds = []
          for(let i = 1; i <= numOfrewardsPerPack.length; i++) {
            expectedRewardIds.push(expectedPackId + i);
          }

          await packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);

          for(let j = 0; j < expectedRewardIds.length; j++) {
            const id = await packHandler.rewardsInPack(expectedPackId, j);
            expect(id).to.equal(expectedRewardIds[j]);            
          }
        }
      })
    })
  })

  describe("State changes in PackERC1155.sol", () => {
    it("Should update the currentTokenId and tokens mapping with relevant token data", async () => {
      for(let packURI of packURIs) {

        const expectedPackId = parseInt((await packERC1155.currentTokenId()).toString());
        const expectedNextPackId = expectedPackId + rewardURIs.length + 1;
        const packMaxSupply = rewardMaxSupplies.reduce((a,b) => a+b);

        await packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);  
        
        expect(parseInt((await packERC1155.currentTokenId()).toString())).to.equal(expectedNextPackId);

        const token = await packERC1155.tokens(expectedPackId);

        expect(token.creator).to.equal(creator.address);
        expect(token.uri).to.equal(packURI)
        expect(token.circulatingSupply).to.equal(packMaxSupply)
        expect(token.tokenType).to.equal(0) // TokenType.Pack == 1
      }
    })

    it("Should update the ERC1155 pack token balance of the creator", async () => {
      for(let packURI of packURIs) {

        const expectedPackId = parseInt((await packERC1155.currentTokenId()).toString());
        const packMaxSupply = rewardMaxSupplies.reduce((a,b) => a+b);

        await packHandler.connect(creator).createPack(packURI, rewardURIs, rewardMaxSupplies);  

        const packBalanceOfCreator = parseInt((await packERC1155.balanceOf(creator.address, expectedPackId)).toString());
        expect(packBalanceOfCreator).to.equal(packMaxSupply)
      }
    })
  })
})