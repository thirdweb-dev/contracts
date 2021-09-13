import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom } from "../utils/hardhatFork";

describe("Create a pack with rewards in a single tx", function () {
  // Signers
  let protocolAdmin: Signer;
  let creator: Signer;

  // Contracts
  let pack: Contract;
  let rewards: Contract;

  // Reward parameterrs
  const rewardURIs: string[] = [
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
  ];
  const rewardSupplies: number[] = [5, 25, 60];
  const rewardsPerOpen: number = 3;

  // Pack parameters
  const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const openStartAndEnd: number = 0;

  // Expected results
  const expectedPackId: number = 0;
  const expectedPackSupply: number = rewardSupplies.reduce((a, b) => a + b) / rewardsPerOpen;
  const expectedRewardIds: number[] = [0, 1, 2];

  beforeEach(async () => {
    // Fork rinkeby
    await forkFrom(9075707, "rinkeby");

    const signers: Signer[] = await ethers.getSigners();
    [protocolAdmin, creator] = signers;

    // Deploy $PACK Protocol
    const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars.rinkeby;

    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    const controlCenter: Contract = await ProtocolControl_Factory.deploy();

    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    pack = await Pack_Factory.deploy(
      controlCenter.address,
      "$PACK Protocol",
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees,
    );

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    const market: Contract = await Market_Factory.deploy(controlCenter.address);

    await controlCenter.initializeProtocol(pack.address, market.address);

    // Deploy Rewardds.sol and create rewards
    const Rewards_factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewards = await Rewards_factory.connect(creator).deploy(pack.address);
  });

  describe("Revert cases", function () {
    it("Should revert if an unequal number of reward IDs and amounts are supplied", async () => {
      await expect(
        rewards
          .connect(creator)
          .createPackAtomic(
            rewardURIs.slice(-2),
            rewardSupplies,
            packURI,
            openStartAndEnd,
            openStartAndEnd,
            rewardsPerOpen,
          ),
      ).to.be.revertedWith("Rewards: Must specify equal number of URIs and supplies.");
    });

    it("Should revert if the creator has not approved the contract to transfer reward tokens", async () => {
      await expect(
        rewards.connect(creator).createPackAtomic([], [], packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen),
      ).to.be.revertedWith("Rewards: Must create at least one reward.");
    });
  });

  describe("Events", function () {
    it("Should emit NativeRewards with the relevant reward info", async () => {
      expect(
        await rewards
          .connect(creator)
          .createPackAtomic(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen),
      )
        .to.emit(rewards, "NativeRewards")
        .withArgs(await creator.getAddress(), expectedRewardIds, rewardURIs, rewardSupplies);
    });

    it("Should emit PackCreated", async () => {
      expect(
        await rewards
          .connect(creator)
          .createPackAtomic(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen),
      ).to.emit(pack, "PackCreated");
    });

    it("Should emit PackCreated with pack related info", async () => {
      const packCreatedPromise = new Promise((resolve, reject) => {
        pack.on("PackCreated", async (_packId, _rewardContract, _creator, _packState, _rewards) => {
          expect(_packId).to.equal(expectedPackId);
          expect(_rewardContract).to.equal(rewards.address);
          expect(_creator).to.equal(await creator.getAddress());
          expect(_packState.uri).to.equal(packURI);
          expect(_packState.currentSupply).to.equal(expectedPackSupply);

          expect(_rewards.source).equal(rewards.address);

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Event timeout: PackCreated"));
        }, 5000);
      });

      await rewards
        .connect(creator)
        .createPackAtomic(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen);

      await packCreatedPromise;
    });
  });

  describe("Balances", function () {
    beforeEach(async () => {
      // Create pack
      await rewards
        .connect(creator)
        .createPackAtomic(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen);
    });

    it("Should lock all reward tokens in the Pack contract", async () => {
      for (let i = 0; i < expectedRewardIds.length; i++) {
        expect(await rewards.balanceOf(await creator.getAddress(), expectedRewardIds[i])).to.equal(0);
        expect(await rewards.balanceOf(pack.address, expectedRewardIds[i])).to.equal(rewardSupplies[i]);
      }
    });

    it("Should mint the total supply of packs to the creator", async () => {
      expect(await pack.balanceOf(await creator.getAddress(), 0)).to.equal(expectedPackSupply);
    });
  });

  describe("Contract state changes", function () {
    beforeEach(async () => {
      // Create pack
      await rewards
        .connect(creator)
        .createPackAtomic(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen);
    });

    it("Should update the next token ID to be one more than the pack's tokenId", async () => {
      expect(await pack.nextTokenId()).to.equal(1);
    });

    it("Should update the `creator` maping with the address of the creator of the pack", async () => {
      expect(await pack.creator(0)).to.equal(await creator.getAddress());
    });

    it("Should update the `tokenURI` mapping with the URI of the pack", async () => {
      expect(await pack.uri(0)).to.equal(packURI);
    });

    it("Should update the `rewards` mapping with the reward contract, IDs and amounts packed", async () => {
      const rewardsInPack = await pack.getRewardsInPack(0);

      expect(rewardsInPack.source).to.equal(rewards.address);
      expect(rewardsInPack.tokenIds.length).to.equal(expectedRewardIds.length);
      expect(rewardsInPack.amountsPacked.length).to.equal(rewardSupplies.length);

      for (let i = 0; i < expectedRewardIds.length; i++) {
        expect(rewardsInPack.tokenIds[i]).to.equal(expectedRewardIds[i]);
        expect(rewardsInPack.amountsPacked[i]).to.equal(rewardSupplies[i]);
      }
    });
  });
});
