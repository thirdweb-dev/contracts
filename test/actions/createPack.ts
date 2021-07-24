import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVarsRinkeby } from "../../utils/chainlink";

describe("Create a pack with rewards using Pack.sol", function() {

  // Signers.
  let deployer: Signer;
  let creator: Signer;

  // Contracts.
  let rewardsContract: Contract;
  let pack: Contract;

  // Reward parameters.
  let numOfRewards: number = 5;
  const rewardURIs: string[] = [];
  const rewardSupplies: BigNumber[] = [];

  // Pack parameters.
  const expectedPackId: BigNumber = BigNumber.from(0)
  const packURI: string = "This is a dummy pack";
  const rewardIds: BigNumber[] = [];
  const openPackLimits: BigNumber = BigNumber.from(0)
  let packTotalSupply: BigNumber = BigNumber.from(0);

  before(() => {
    // Fill in reward and pack parameters
    for(let i = 0; i < numOfRewards; i++) {

      // Reward params
      rewardURIs.push(`This is a dummy URI - ${i}`);
      rewardSupplies.push(
        BigNumber.from(
          Math.floor(Math.random() * 100) + 10
        )
      );

      // Pack params;
      rewardIds.push(BigNumber.from(i));
      packTotalSupply = packTotalSupply.add(rewardSupplies[i]);
    }
  })

  beforeEach(async () => {
    // Get signers
    [deployer, creator] = await ethers.getSigners();
    
    // Get contracts.
    const RewardsContract_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewardsContract = await RewardsContract_Factory.connect(deployer).deploy();

    // 1. Deploy ControlCenter
    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    const controlCenter: Contract = await ProtocolControl_Factory.deploy(await deployer.getAddress());

    // 2. Deploy rest of the protocol modules.
    const packContractURI: string = "$PACK Protocol"
    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    pack = await Pack_Factory.deploy(controlCenter.address, packContractURI);

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    const market: Contract = await Market_Factory.deploy(controlCenter.address);

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVarsRinkeby;
    const fees: BigNumber = ethers.utils.parseEther("0.1");
    
    const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
    const rng: Contract = await RNG_Factory.deploy(
      controlCenter.address,
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
    );

    // Initialize $PACK Protocol in ControlCenter
    await controlCenter.initPackProtocol(
      pack.address,
      market.address,
      rng.address,
    );

    // Create rewards
    await rewardsContract.connect(creator).createNativeRewards(rewardURIs, rewardSupplies)
  })

  describe("Revert cases", function() {

    it("Should revert if an unequal number of reward IDs and amounts are supplied", async () => {
      await expect(pack.connect(creator).createPack(
        packURI,
        rewardsContract.address,
        rewardIds,
        rewardSupplies.slice(-2),
        openPackLimits,
        openPackLimits
      ))
      .to.be.revertedWith("Pack: unequal number of reward IDs and reward amounts provided.")
    })

    it("Should revert if the creator has not approved the contract to transfer reward tokens", async () => {
      await expect(pack.connect(creator).createPack(
        packURI,
        rewardsContract.address,
        rewardIds,
        rewardSupplies,
        openPackLimits,
        openPackLimits
      ))
      .to.be.revertedWith("Pack: not approved to transer the reward tokens.")
    })
  })

  describe("Events", function() {
    beforeEach(async () => {
      // Approve Pack to transfer reward tokens
      await rewardsContract.connect(creator).setApprovalForAll(pack.address, true);
    })

    it("Should emit PackCreated with pack related info", async () => {


      const packCreatedPromise = new Promise((resolve, reject) => {
        pack.on("PackCreated", async (_rewardContract, _creator, _packId, _packURI, _packTotalSupply) => {
          
          expect(_rewardContract).to.equal(rewardsContract.address)
          expect(_creator).to.equal(await creator.getAddress())
          expect(_packId).to.equal(expectedPackId)
          expect(_packURI).to.equal(packURI)
          expect(_packTotalSupply).to.equal(packTotalSupply)

          resolve(null);
        })

        setTimeout(() => {
          reject(new Error("Event timeout: PackCreated"))
        }, 5000)
      })

      await pack.connect(creator).createPack(
        packURI,
        rewardsContract.address,
        rewardIds,
        rewardSupplies,
        openPackLimits,
        openPackLimits
      )

      await packCreatedPromise;
    })

    it("Should emit PackRewards with info related to a pack's underlying rewards", async () => {

      const packRewardsPromise = new Promise((resolve, reject) => {
        pack.on("PackRewards", async (_packId, _rewardContract, _rewardIds, _rewardAmounts) => {
          
          expect(_rewardContract).to.equal(rewardsContract.address)
          expect(_packId).to.equal(expectedPackId)
          
          expect(_rewardIds.length).to.equal(rewardIds.length);
          expect(_rewardAmounts.length).to.equal(rewardSupplies.length);

          for(let i = 0; i < _rewardIds.length; i++) {
            expect(_rewardIds[i]).to.equal(rewardIds[i])
            expect(_rewardAmounts[i]).to.equal(rewardSupplies[i])
          }

          resolve(null);
        })

        setTimeout(() => {
          reject(new Error("Event timeout: PackRewards"))
        }, 5000)
      })

      await pack.connect(creator).createPack(
        packURI,
        rewardsContract.address,
        rewardIds,
        rewardSupplies,
        openPackLimits,
        openPackLimits
      )

      await packRewardsPromise;
    })
  })

  describe("Balances", function() {
    beforeEach(async () => {
      // Approve Pack to transfer reward tokens
      await rewardsContract.connect(creator).setApprovalForAll(pack.address, true);
      // Create pack
      await pack.connect(creator).createPack(
        packURI,
        rewardsContract.address,
        rewardIds,
        rewardSupplies,
        openPackLimits,
        openPackLimits
      )
    })

    it("Should lock all reward tokens in the Pack contract", async () => {

      for(let i = 0; i < rewardIds.length; i++) {
        expect(await rewardsContract.balanceOf(await creator.getAddress(), rewardIds[i])).to.equal(BigNumber.from(0));
        expect(await rewardsContract.balanceOf(pack.address, rewardIds[i])).to.equal(rewardSupplies[i]);
      }
    })

    it("Should mint the total supply of packs to the creator", async () => {
      expect(await pack.balanceOf(await creator.getAddress(), expectedPackId)).to.equal(packTotalSupply)
    })
  })

  describe("Contract state changes", function() {
    beforeEach(async () => {
      // Approve Pack to transfer reward tokens
      await rewardsContract.connect(creator).setApprovalForAll(pack.address, true);
      // Create pack
      await pack.connect(creator).createPack(
        packURI,
        rewardsContract.address,
        rewardIds,
        rewardSupplies,
        openPackLimits,
        openPackLimits
      )
    })

    it("Should update the next token ID to be one more than the pack's tokenId", async () => {
      expect(await pack.nextTokenId()).to.equal( expectedPackId.add(BigNumber.from(1)) )
    })

    it("Should update the `creator` maping with the address of the creator of the pack", async () => {
      expect(await pack.creator(expectedPackId)).to.equal(await creator.getAddress())
    })

    it("Should update the `tokenURI` mapping with the URI of the pack", async () => {
      expect(await pack.tokenURI(expectedPackId)).to.equal(packURI)
    })

    it("Should update the `rewards` mapping with the reward contract, IDs and amounts packed", async () => {
      const rewards = await pack.getRewards(expectedPackId);

      expect(rewards.source).to.equal(rewardsContract.address)
      expect(rewards.tokenIds.length).to.equal(rewardIds.length)
      expect(rewards.amountsPacked.length).to.equal(rewardSupplies.length)

      for(let i = 0; i < rewardIds.length; i++) {
        expect(rewards.tokenIds[i]).to.equal(rewardIds[i])
        expect(rewards.amountsPacked[i]).to.equal(rewardSupplies[i])
      }
    })
  })
})