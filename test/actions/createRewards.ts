import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

describe("Create rewards using the cannon Rewards.sol contract", function() {

  // Signers.
  let deployer: Signer;
  let creator: Signer;

  // Contracts.
  let rewardsContract: Contract;

  // Reward parameters.
  let numOfRewards: number = 5;
  const rewardURIs: string[] = [];
  const rewardSupplies: BigNumber[] = [];

  before(() => {
    // Fill in reward parameters
    for(let i = 0; i < numOfRewards; i++) {

      rewardURIs.push(`This is a dummy URI - ${i}`);
      rewardSupplies.push(
        BigNumber.from(
          Math.floor(Math.random() * 100) + 10
        )
      );
    }
  })
  
  beforeEach(async () => {
    // Get signers
    [deployer, creator] = await ethers.getSigners();
    
    // Get contract.
    const RewardsContract_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewardsContract = await RewardsContract_Factory.connect(deployer).deploy();
  })

  describe("Revert cases", () => {

    it("Should revert if an unequal number of reward URIs and supplies are specified", async () => {
      await expect(rewardsContract.connect(creator).createNativeRewards(rewardURIs.slice(0, -1), rewardSupplies))
        .to.be.revertedWith("Rewards: Must specify equal number of URIs and supplies.")
    })

    it("Should revert if no reward URIs or supplies are provided", async () => {
      await expect(rewardsContract.connect(creator).createNativeRewards([], []))
        .to.be.revertedWith("Rewards: Must create at least one reward.")
    })
  })

  describe("Events", () => {

    it("Should emit NativeRewards with reward creator, IDs, URIs and supplies", async () => {

      const creatorAddress: string = await creator.getAddress()
      const expectedRewardIds: BigNumber[] = [0,1,2,3,4].map(num => BigNumber.from(num));

      expect(await rewardsContract.connect(creator).createNativeRewards(rewardURIs, rewardSupplies))
        .to.emit(rewardsContract, "NativeRewards")
        .withArgs(creatorAddress, expectedRewardIds, rewardURIs, rewardSupplies)
    })
  })

  describe("ERC 1155 token balances", function() {

    this.beforeEach(async () => {
      // Create rewards.
      await rewardsContract.connect(creator).createNativeRewards(rewardURIs, rewardSupplies)
    })

    it("Should mint the specified amount of rewards to the creator", async () => {

      const creatorAddress: string = await creator.getAddress()
      const expectedRewardIds: BigNumber[] = [0,1,2,3,4].map(num => BigNumber.from(num));

      for(let i = 0; i < expectedRewardIds.length; i++) {
        expect(await rewardsContract.balanceOf(creatorAddress, expectedRewardIds[i])).to.equal(rewardSupplies[i])
      }
    })
  })

  describe("Contract state changes", function() {

    this.beforeEach(async () => {
      // Create rewards.
      await rewardsContract.connect(creator).createNativeRewards(rewardURIs, rewardSupplies)
    })

    it("Should increment `nextTokenId` by the number of rewards created", async () => {
      const numOfRewardsCreated: BigNumber = BigNumber.from(numOfRewards);
      expect(await rewardsContract.nextTokenId()).to.equal(numOfRewardsCreated);
    })

    it("Should update the `rewards` mapping for each reward created", async () => {

      const creatorAddress: string = await creator.getAddress()
      const expectedRewardIds: BigNumber[] = [0,1,2,3,4].map(num => BigNumber.from(num));

      for(let i = 0; i < expectedRewardIds.length; i++) {
        const reward = await rewardsContract.rewards(expectedRewardIds[i]);

        expect(reward.uri).to.equal(rewardURIs[i])
        expect(reward.supply).to.equal(rewardSupplies[i]);
        expect(reward.creator).to.equal(creatorAddress);
        expect(reward.underlyingType).to.equal(0) // 0 == UnderlyingType.None
      }
    })
  })
})