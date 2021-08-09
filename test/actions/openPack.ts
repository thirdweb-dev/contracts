import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../../utils/chainlink";
import { pairs } from "../../utils/ammPairs"
import { forkFrom } from "../../utils/mainnetFork";

describe("Buy packs using Market.sol", function() {
  // Signers.
  let deployer: Signer;
  let creator: Signer;
  let fan: Signer;

  // Contracts.
  let rewardsContract: Contract;
  let pack: Contract;
  let market: Contract;
  let rng: Contract;

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

  // List packs on sale: Market parameters
  const expectedListingId: BigNumber = BigNumber.from(0);
  const currency: string = "0x0000000000000000000000000000000000000000";
  const pricePerToken: BigNumber = ethers.utils.parseEther("0.01");
  const saleWindowLimits: BigNumber = BigNumber.from(0)

  // Buy packs from market: Market parameters
  const quantityToBuy: BigNumber = BigNumber.from(1)

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
    // Fork mainnet
    await forkFrom(12845437);
    
    // Get signers
    [deployer, creator, fan] = await ethers.getSigners();
    
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
    market = await Market_Factory.deploy(controlCenter.address);

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVars.rinkeby;
    const fees: BigNumber = ethers.utils.parseEther("0.1");
    
    const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
    rng = await RNG_Factory.deploy(
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

    // Initialize RNG
    for(let pair of pairs) {
      await rng.addPair(pair.pair);
    }

    // Create rewards
    await rewardsContract.connect(creator).createNativeRewards(rewardURIs, rewardSupplies)

    // Create pack
    await rewardsContract.connect(creator).setApprovalForAll(pack.address, true);
    await pack.connect(creator).createPack(packURI, rewardsContract.address, rewardIds, rewardSupplies, openPackLimits, openPackLimits);

    // List packs on sale
    await pack.connect(creator).setApprovalForAll(market.address, true);
    await market.connect(creator).list(pack.address, expectedPackId, currency, pricePerToken, packTotalSupply, saleWindowLimits, saleWindowLimits);

    // Buy packs
    await market.connect(fan).buy(await creator.getAddress(), expectedListingId, quantityToBuy, { value: pricePerToken.mul(quantityToBuy) });
  })

  describe("Revert cases", function() {

    it("Should revert if opener has no packs to open", async () => {
      await expect(pack.connect(deployer).openPack(expectedPackId))
        .to.be.revertedWith("Pack: sender owns no packs of the given packId.")
    })
  })

  describe("Events", function() {

    it("Should emit PackOpened with the pack's tokenId and the opener's address", async () => {
      expect(await pack.connect(fan).openPack(expectedPackId))
        .to.emit(pack, "PackOpened")
        .withArgs(expectedPackId, await fan.getAddress())
    })

    it("Should emit RewardDistributed with info about the reward distributed to opener", async () => {
      const rewardDistributedPromise = new Promise((resolve, reject) => {
        pack.on("RewardDistributed", async (_rewardContract, _receiver, _packId, _rewardId) => {
          expect(_rewardContract).to.equal(rewardsContract.address)
          expect(_receiver).to.equal(await fan.getAddress())
          expect(_packId).to.equal(expectedPackId)

          let validRewardId: boolean = false

          for(let id of rewardIds) {
            if((id as BigNumber).eq(_rewardId)) validRewardId = true;
          }

          expect(validRewardId).to.equal(true);
          
          resolve(null);
        })

        setTimeout(() => {
          reject(new Error("Event timeout: RewardDistributed"))
        }, 10000)
      })

      await pack.connect(fan).openPack(expectedPackId)

      await rewardDistributedPromise
    })

    it("Should emit RandomNumber in the RNG with the address of the opener", async () => {
      const rngPromise = new Promise((resolve, reject) => {
        rng.on("RandomNumber", async (_requestor) => {
          expect(_requestor).to.equal(await fan.getAddress())

          resolve(null)
        })

        setTimeout(() => {
          reject(new Error("Event timeout: RandomNumber"))
        }, 5000)
      })

      await pack.connect(fan).openPack(expectedPackId)

      await rngPromise;
    })
  })

  describe("Balances", function() {

    let rewardId: BigNumber;

    beforeEach(async () => {
      // Open Pack and get reward Id
      const rewardDistributedPromise = new Promise((resolve, reject) => {
        pack.on("RewardDistributed", async (_rewardContract, _receiver, _packId, _rewardId) => {
          rewardId = _rewardId
          
          resolve(null);
        })

        setTimeout(() => {
          reject(new Error("Event timeout: RewardDistributed"))
        }, 5000)
      })

      // Open pack
      await pack.connect(fan).openPack(expectedPackId)
      // get rewardId
      await rewardDistributedPromise
    })

    it("Should burn one pack owned by the opener", async () => {
      expect(await pack.balanceOf(await fan.getAddress(), expectedPackId)).to.equal(quantityToBuy.sub(BigNumber.from(1)))
    })

    it("Should mint one underlying reward to the opener", async () => {
      expect(await rewardsContract.balanceOf(await fan.getAddress(), rewardId)).to.equal(BigNumber.from(1));
    })
  })

  describe("Contract state changes", function() {
    beforeEach(async () => {
      // Open pack
      await pack.connect(fan).openPack(expectedPackId)
    })

    it("Should update the `totalSupply` mapping to account for the burning of the pack", async () => {
      expect(await pack.totalSupply(expectedPackId)).to.equal(packTotalSupply.sub(BigNumber.from(1)))
    })
  })
})