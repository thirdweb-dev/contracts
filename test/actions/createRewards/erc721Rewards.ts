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
  let nftContract: Contract;

  // Reward parameters.
  const expectedNftTokenId: BigNumber = BigNumber.from(0)
  const expectedRewardId: BigNumber = BigNumber.from(0)
  const rewardURI: string = "This reward can be redeemed for an ERC721 NFT."

  beforeEach(async () => {
    // Get signers
    [deployer, creator, fan] = await ethers.getSigners();
    
    // Get contracts.
    const RewardsContract_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewardsContract = await RewardsContract_Factory.connect(deployer).deploy();

    const NftContract_Factory: ContractFactory = await ethers.getContractFactory("NFT");
    nftContract = await NftContract_Factory.connect(creator).deploy()

    // Mint one NFT
    await nftContract.mint(await creator.getAddress());
  })

  describe("Revert cases", async () => {

    it("Should revert if someone other than the NFT owner tried to wrap the NFT", async () => {
      // Fan tries to wrap an NFT owned by the creator.
      await expect(rewardsContract.connect(fan).wrapERC721(nftContract.address, expectedNftTokenId, rewardURI))
        .to.be.revertedWith("Rewards: Only the owner of the NFT can wrap it.")
    })

    it("Should revert if the Rewards contract is not approved to transfer the NFT", async () => {
      // Creator tries to wrap NFT without  approving the reward contract to transfer the NFT.
      await expect(rewardsContract.connect(creator).wrapERC721(nftContract.address, expectedNftTokenId, rewardURI))
        .to.be.revertedWith("Rewards: Must approve the contract to transfer the NFT.")
    })
  })

  describe("Events", function() {

    beforeEach(async () => {
      // Creator approves reward contract to transfer NFT.
      await nftContract.connect(creator).approve(rewardsContract.address, expectedNftTokenId);
    })

    it("Should emit ERC721Rewards with the NFT and wrapped token info", async () => {
      expect(await rewardsContract.connect(creator).wrapERC721(nftContract.address, expectedNftTokenId, rewardURI))
        .to.emit(rewardsContract, "ERC721Rewards")
        .withArgs(await creator.getAddress(), nftContract.address, expectedNftTokenId, expectedRewardId, rewardURI)
    })
  })

  describe("ERC1155 and ERC721 token balances", function() {
    beforeEach(async () => {
      // Creator approves reward contract to transfer NFT.
      await nftContract.connect(creator).approve(rewardsContract.address, expectedNftTokenId);

      // Wrap the NFT.
      await rewardsContract.connect(creator).wrapERC721(nftContract.address, expectedNftTokenId, rewardURI)
    })

    it("Should change the owner of the NFT from the creator to the Rewards contract", async () => {
      expect(await nftContract.balanceOf(await creator.getAddress())).to.equal(BigNumber.from(0))
      expect(await nftContract.ownerOf(expectedNftTokenId)).to.equal(rewardsContract.address)
    })

    it("Should assert the creator as the owner of the created reward token", async () => {
      expect(await rewardsContract.balanceOf(await creator.getAddress(), expectedRewardId)).to.equal(BigNumber.from(1));
    })
  })

  describe("Contract state changes", function() {
    beforeEach(async () => {
      // Creator approves reward contract to transfer NFT.
      await nftContract.connect(creator).approve(rewardsContract.address, expectedNftTokenId);

      // Wrap the NFT.
      await rewardsContract.connect(creator).wrapERC721(nftContract.address, expectedNftTokenId, rewardURI)
    })

    it("Should increment the reward contract's tokenId tracker by 1", async () => {
      expect(await rewardsContract.nextTokenId()).to.equal(BigNumber.from(1));
    })

    it("Should update the `rewards` mapping with the right reward info", async () => {
      const reward = await rewardsContract.rewards(expectedRewardId)

      expect(reward.creator).to.equal(await creator.getAddress())
      expect(reward.uri).to.equal(rewardURI)
      expect(reward.supply).to.equal(BigNumber.from(1))
      expect(reward.underlyingType).to.equal(BigNumber.from(2)) // 1 == UnderlyingType.ERC721
    })

    it("should update the `erc721Rewards` mapping with the underlying NFT info", async () => {
      const underlyingNFT = await rewardsContract.erc721Rewards(expectedRewardId)

      expect(underlyingNFT.nftContract).to.equal(nftContract.address)
      expect(underlyingNFT.nftTokenId).to.equal(expectedNftTokenId)
    })
  })

  describe("Redeeming ERC721 NFT", function() {
    beforeEach(async () => {
      // Creator approves reward contract to transfer NFT.
      await nftContract.connect(creator).approve(rewardsContract.address, expectedNftTokenId);

      // Wrap the NFT.
      await rewardsContract.connect(creator).wrapERC721(nftContract.address, expectedNftTokenId, rewardURI)

      // Airdrop reward to fan.
      const from: string = await creator.getAddress()
      const to: string = await fan.getAddress()
      const id: BigNumber = expectedRewardId
      const amount: BigNumber = BigNumber.from(1);
      const data: BytesLike = ethers.utils.toUtf8Bytes("");

      await rewardsContract.connect(creator).safeTransferFrom(from, to, id, amount, data)
    })

    it("Should revert if someone other than the owner tries to redeem the reward", async () => {
      await expect(rewardsContract.connect(creator).redeemERC721(expectedRewardId))
        .to.be.revertedWith("Rewards: Cannot redeem a reward you do not own.");
    })

    it("Should emit ERC721Redeemed when the NFT is redeemed", async () => {
      expect(await rewardsContract.connect(fan).redeemERC721(expectedRewardId))
        .to.emit(rewardsContract, "ERC721Redeemed")
        .withArgs(await fan.getAddress(), nftContract.address, expectedNftTokenId, expectedRewardId)
    })

    it("Should burn the reward token used to redeem the NFT, and transfer the NFT to the redeemer", async () => {
      
      expect(await rewardsContract.balanceOf(await fan.getAddress(), expectedRewardId)).to.equal(BigNumber.from(1));
      await rewardsContract.connect(fan).redeemERC721(expectedRewardId)
      expect(await rewardsContract.balanceOf(await fan.getAddress(), expectedRewardId)).to.equal(BigNumber.from(0));

      const reward = await rewardsContract.rewards(expectedRewardId);
      expect(reward.supply).to.equal(BigNumber.from(0));

      expect(await nftContract.ownerOf(expectedNftTokenId)).to.equal(await fan.getAddress());
    })
  })
})