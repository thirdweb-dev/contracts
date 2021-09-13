import { ethers, network } from "hardhat";
import { Signer, Contract, ContractFactory, BytesLike, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom, impersonate } from "../utils/hardhatFork";
import { setTimeout } from "timers";
import linkTokenABi from "../abi/LinkTokenInterface.json";

describe("Fulfill a request to open a pack", function () {
  // Signers
  let protocolAdmin: Signer;
  let creator: Signer;
  let vrf: Signer;

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
  const rewardsPerOpen: number = 6;

  // Pack parameters
  const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const openStartAndEnd: number = 0;

  // Randomness request parameters
  let requestId: BytesLike;
  const randomNumber: number = Math.floor(Math.random() * 10000 + 1000);

  // Expected results
  const expectedPackId: number = 0;
  const expectedRewardIds: number[] = [0, 1, 2];

  // Fund `Pack` with LINK
  const fundPack = async () => {
    const { linkTokenAddress } = chainlinkVars.rinkeby;

    const linkHolderAddress: string = "0xa7a82dd06901f29ab14af63faf3358ad101724a8";
    await impersonate(linkHolderAddress);
    const linkHolder: Signer = await ethers.getSigner(linkHolderAddress);

    const linkContract = await ethers.getContractAt(linkTokenABi, linkTokenAddress);
    linkContract.connect(linkHolder).transfer(pack.address, ethers.utils.parseEther("1"));
  };

  // Impersonate Chainlink VRF: setup
  const impersonateChainlinkVRF = async (): Promise<Signer> => {
    const { vrfCoordinator } = chainlinkVars.rinkeby;

    // Impersonate VRF
    await impersonate(vrfCoordinator);
    const vrf: Signer = await ethers.getSigner(vrfCoordinator);

    await network.provider.send("hardhat_setBalance", [vrfCoordinator, "0xDE0B6B3A7640000"]);

    return vrf;
  };

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

    // Create pack with rewards.
    await rewards
      .connect(creator)
      .createPackAtomic(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen);

    // Fund `Pack` contract
    await fundPack();

    // Open Pack : get requestId
    const openPackPromise = new Promise((resolve, reject) => {
      pack.on("PackOpenRequest", (_packId, _caller, _requestId) => {
        requestId = _requestId;

        resolve(null);
      });

      setTimeout(() => {
        reject(new Error("Timeout: PackOpenRequest"));
      }, 5000);
    });

    await pack.connect(creator).openPack(expectedPackId);
    await openPackPromise;

    // Impersonate vrf
    vrf = await impersonateChainlinkVRF();
  });

  // describe("Revert cases", function () {
  //   it("Should revert if caller is not VRF coordinator", async () => {
  //     await expect(pack.connect(protocolAdmin).rawFulfillRandomness(requestId, randomNumber)).to.be.revertedWith(
  //       "Only VRFCoordinator can fulfill",
  //     );
  //   });
  // });

  describe("Events", function () {
    it("Should emit PackOpenFulfilled", async () => {
      const fulfillRandomnessPromise = new Promise((resolve, reject) => {
        pack.on("PackOpenFulfilled", async (_packId, _opener, _requestId, _source, _rewardIds) => {
          expect(_packId).to.equal(expectedPackId);
          expect(_opener).to.equal(await creator.getAddress());
          expect(_requestId).to.equal(requestId);
          expect(_source).to.equal(rewards.address);
          // expect(expectedRewardIds.includes(parseInt(_rewardId.toString()))).to.equal(true);

          console.log("Reward IDs: ", _rewardIds);

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: PackOpenFulfilled"));
        }, 5000);
      });

      await pack.connect(vrf).rawFulfillRandomness(requestId, randomNumber);
      await fulfillRandomnessPromise;
    });
  });

  // describe("Balances", function () {
  //   it("Should increase the reward token balance of the pack opener by one", async () => {
  //     let rewardId: number = 0;
  //     const fulfillRandomnessPromise = new Promise((resolve, reject) => {
  //       pack.on("PackOpenFulfilled", (_packId, _opener, _requestId, _source, _rewardId) => {
  //         rewardId = parseInt(_rewardId.toString());
  //         resolve(null);
  //       });

  //       setTimeout(() => {
  //         reject(new Error("Timeout: PackOpenFulfilled"));
  //       }, 5000);
  //     });

  //     await pack.connect(vrf).rawFulfillRandomness(requestId, randomNumber);
  //     await fulfillRandomnessPromise;

  //     expect(await rewards.balanceOf(await creator.getAddress(), rewardId)).to.equal(BigNumber.from(1));
  //   });

  //   it("Should decrease the reward token balance of the contract by one", async () => {
  //     let rewardId: number = 0;
  //     const fulfillRandomnessPromise = new Promise((resolve, reject) => {
  //       pack.on("PackOpenFulfilled", (_packId, _opener, _requestId, _source, _rewardId) => {
  //         rewardId = parseInt(_rewardId.toString());
  //         resolve(null);
  //       });

  //       setTimeout(() => {
  //         reject(new Error("Timeout: PackOpenFulfilled"));
  //       }, 5000);
  //     });

  //     await pack.connect(vrf).rawFulfillRandomness(requestId, randomNumber);
  //     await fulfillRandomnessPromise;

  //     const idx = expectedRewardIds.indexOf(rewardId);
  //     const expectedRewardSupply = rewardSupplies[idx] - 1;

  //     expect(await rewards.balanceOf(pack.address, rewardId)).to.equal(expectedRewardSupply);
  //   });
  // });

  // describe("Contract state changes", function () {
  //   it("Should show no pending requests for the opener and the particular pack", async () => {
  //     await pack.connect(vrf).rawFulfillRandomness(requestId, randomNumber);
  //     const isPending: boolean = await pack.pendingRequests(expectedPackId, await creator.getAddress());
  //     expect(isPending).to.equal(false);
  //   });
  // });
});
