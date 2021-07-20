import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber, BytesLike } from "ethers";
import { expect } from "chai";

describe("Create ERC721 rewards using the cannon Rewards.sol contract", function() {
  // Signers.
  let deployer: Signer;
  let creator: Signer;
  let fan: Signer;

  // Contracts.
  let rewardsContract: Contract;
  let tokenContract: Contract;

  /**
   * We create 3 kinds of rewards. 1) 1 reward is 70/700 = 0.1 tokens    2) 1 reward is 25/50 = 0.5 tokens     3) 1 reward is 5/1 = 5 tokens
   */
  const tokenAmountToMint: BigNumber = ethers.utils.parseEther("100"); // Total amount of ERC20 tokens.

  const tokensPerReward: BigNumber[] = ["70", "25", "5"].map(num => ethers.utils.parseEther(num)) // Amount of tokens to allocate per reward category.

  const numOfRewardsToMint: BigNumber[] = [700, 50, 1].map(num => BigNumber.from(num)) // Number of reward tokens to mint per reward category.

  // Reward parameters.
  const rewardURI: string = "This reward can be redeemed for ERC20 tokens."
  const expectedRewardIds: BigNumber[] = [0,1,2].map(num => BigNumber.from(num))

  beforeEach(async () => {
    // Get signers
    [deployer, creator, fan] = await ethers.getSigners();
    
    // Get contracts.
    const RewardsContract_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewardsContract = await RewardsContract_Factory.connect(deployer).deploy();

    const TokenContract_Factory: ContractFactory = await ethers.getContractFactory("Coin");
    tokenContract = await TokenContract_Factory.connect(creator).deploy()

    // Mint ERC20 tokens
    await tokenContract.connect(creator).mint(await creator.getAddress(), tokenAmountToMint);
  })

  describe("Revert cases", function() {
    
    it("Should revert if the account does not own the amount of tokens being wrapped", async () => {
      // Fan does not own any ERC20 tokens.
      await expect(rewardsContract.connect(fan).wrapERC20(tokenContract.address, tokensPerReward[0], numOfRewardsToMint[0], rewardURI))
        .to.be.revertedWith("Rewards: Must own the amount of tokens that are being wrapped.")
    })

    it("Should revert if the account had not approved the reward contract to transfer tokens", async () => {
      // Creator has not approved the reward contract to transfer tokens.
      await expect(rewardsContract.connect(creator).wrapERC20(tokenContract.address, tokensPerReward[0], numOfRewardsToMint[0], rewardURI))
        .to.be.revertedWith("Rewards: Must approve this contract to transfer ERC20 tokens.")
    })
  })

  describe("Events", function() {

    beforeEach(async () => {
      // Approve rewards contract to transfer ERC20 tokens
      await tokenContract.connect(creator).approve(rewardsContract.address, tokenAmountToMint);
    })

    it("Should emit ERC20Rewards with the reward and underlying ERC20 token info", async () => {
      for(let i = 0; i < tokensPerReward.length; i++) {
        expect(await rewardsContract.connect(creator).wrapERC20(tokenContract.address, tokensPerReward[i], numOfRewardsToMint[i], rewardURI))
          .to.emit(rewardsContract, "ERC20Rewards")
          .withArgs(await creator.getAddress(), tokenContract.address, tokensPerReward[i], numOfRewardsToMint[i], rewardURI)
      }
    })
  })

  describe("ERC 1155 and ERC 20 token balances", async () => {

    beforeEach(async () => {
      // Approve rewards contract to transfer ERC20 tokens
      await tokenContract.connect(creator).approve(rewardsContract.address, tokenAmountToMint);
      
      // Create all 3 kinds of rewards.
      for(let i = 0; i < tokensPerReward.length; i++) {
        await rewardsContract.connect(creator).wrapERC20(tokenContract.address, tokensPerReward[i], numOfRewardsToMint[i], rewardURI)
      }
    })

    it("Should transfer all ERC20 tokens from the creator to the reward contract", async () => {
      expect(await tokenContract.balanceOf(await creator.getAddress())).to.equal(BigNumber.from(0));
      expect(await tokenContract.balanceOf(rewardsContract.address)).to.equal(tokenAmountToMint);
    })

    it("Should mint reward tokens to the creator", async () => {
      for(let i = 0; i < expectedRewardIds.length; i++) {
        expect(await rewardsContract.balanceOf(await creator.getAddress(), expectedRewardIds[i])).to.equal(numOfRewardsToMint[i]);
      }
    })
  })
  
  describe("Contract state changes",function() {
    
    beforeEach(async () => {
      // Approve rewards contract to transfer ERC20 tokens
      await tokenContract.connect(creator).approve(rewardsContract.address, tokenAmountToMint);
      
      // Create all 3 kinds of rewards.
      for(let i = 0; i < tokensPerReward.length; i++) {
        await rewardsContract.connect(creator).wrapERC20(tokenContract.address, tokensPerReward[i], numOfRewardsToMint[i], rewardURI)
      }
    })

    it("Should icrement the reward contract's nextTokenId by the number of rewards created", async () => {
      const numOfRewards: BigNumber = BigNumber.from(expectedRewardIds.length)
      expect(await rewardsContract.nextTokenId()).to.equal(numOfRewards);
    })

    it("Should update the `rewards` mapping with the rewards info", async () => {
      for(let i = 0; i < expectedRewardIds.length; i++) {
        const reward = await rewardsContract.rewards(expectedRewardIds[i])

        expect(reward.creator).to.equal(await creator.getAddress())
        expect(reward.supply).to.equal(numOfRewardsToMint[i])
        expect(reward.uri).to.equal(rewardURI);
        expect(reward.underlyingType).to.equal(BigNumber.from(1)) // 1 == ERC20
      }
    })

    it("Should update the `erc20Rewards` mapping with the ERC20 reward info", async () => {
      for(let i = 0; i < expectedRewardIds.length; i++) {
        const erc20Reward = await rewardsContract.erc20Rewards(expectedRewardIds[i]);

        expect(erc20Reward.tokenContract).to.equal(tokenContract.address);
        expect(erc20Reward.numOfRewards).to.equal(numOfRewardsToMint[i])
        expect(erc20Reward.underlyingTokenAmount).to.equal(tokensPerReward[i]);
      }
    })
  })

  describe("Redeeming ERC 20 tokens", function() {
    beforeEach(async () => {
      // Approve rewards contract to transfer ERC20 tokens
      await tokenContract.connect(creator).approve(rewardsContract.address, tokenAmountToMint);
      
      // Create all 3 kinds of rewards., and airdrop one of each to fan.
      for(let i = 0; i < expectedRewardIds.length; i++) {
        await rewardsContract.connect(creator).wrapERC20(tokenContract.address, tokensPerReward[i], numOfRewardsToMint[i], rewardURI)
        
        // Airdrop reward to fan.
        const from: string = await creator.getAddress()
        const to: string = await fan.getAddress()
        const id: BigNumber = expectedRewardIds[i]
        const amount: BigNumber = BigNumber.from(1);
        const data: BytesLike = ethers.utils.toUtf8Bytes("");
        
        await rewardsContract.connect(creator).safeTransferFrom(from, to, id, amount, data);
      }
    })

    it("Should revert if an account tries to redeem tokens without owning a reward", async () => {
      // Anon account (here, `deployer`) tries to redeem ERC20 tokens
      await expect(rewardsContract.connect(deployer).redeemERC20(expectedRewardIds[0], BigNumber.from(1)))
        .to.be.revertedWith("Rewards: Cannot redeem a reward you do not own.");
    })

    it("Should emit ERC20Redeemed when a reward is redeemed for underlying ERC20 tokens", async () => {
      for(let i = 0; i < expectedRewardIds.length; i++) {

        const rewardsRedeemed: BigNumber = BigNumber.from(1);
        const tokensReceived: BigNumber = tokensPerReward[i].div(numOfRewardsToMint[i]);

        expect(await rewardsContract.connect(fan).redeemERC20(expectedRewardIds[i], BigNumber.from(1)))
          .to.emit(rewardsContract, "ERC20Redeemed")
          .withArgs(await fan.getAddress(), tokenContract.address, tokensReceived, rewardsRedeemed);
      }
    })

    it("Should update fan's ERC20 and ERC 1155 token balances", async () => {

      let totalTokensRedeemed: BigNumber = BigNumber.from(0);

      expect(await tokenContract.balanceOf(rewardsContract.address)).to.equal(tokenAmountToMint);

      for(let i = 0; i < expectedRewardIds.length; i++) {
        await rewardsContract.connect(fan).redeemERC20(expectedRewardIds[i], BigNumber.from(1))

        expect(await rewardsContract.balanceOf(await fan.getAddress(), expectedRewardIds[i])).to.equal(BigNumber.from(0));

        const tokensReceived: BigNumber = tokensPerReward[i].div(numOfRewardsToMint[i]);
        totalTokensRedeemed = totalTokensRedeemed.add(tokensReceived);

        expect(await tokenContract.balanceOf(await fan.getAddress())).to.equal(totalTokensRedeemed);
      }

      expect(await tokenContract.balanceOf(rewardsContract.address)).to.equal(tokenAmountToMint.sub(totalTokensRedeemed));
    })

  })
})