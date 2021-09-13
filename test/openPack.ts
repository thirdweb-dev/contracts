import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BytesLike, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom, impersonate } from "../utils/hardhatFork";
import { setTimeout } from "timers";
import linkTokenABi from "../abi/LinkTokenInterface.json";

describe("Request to open a pack", function () {
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

  // Fund `Pack` with LINK
  const fundPack = async () => {
    const { linkTokenAddress } = chainlinkVars.rinkeby;

    const linkHolderAddress: string = "0xa7a82dd06901f29ab14af63faf3358ad101724a8";
    await impersonate(linkHolderAddress);
    const linkHolder: Signer = await ethers.getSigner(linkHolderAddress);

    const linkContract = await ethers.getContractAt(linkTokenABi, linkTokenAddress);
    linkContract.connect(linkHolder).transfer(pack.address, ethers.utils.parseEther("1"));
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
  });

  describe("Revert cases", function () {
    it("Should revert if the contract has no LINK", async () => {
      await expect(pack.connect(creator).openPack(expectedPackId)).to.be.revertedWith(
        "Pack: Not enough LINK to fulfill randomness request.",
      );
    });

    it("Should revert if the caller has no packs to open", async () => {
      // Fund `Pack` with LINK
      await fundPack();

      await expect(pack.connect(protocolAdmin).openPack(expectedPackId)).to.be.revertedWith(
        "Pack: sender owns no packs of the given packId.",
      );
    });

    it("Should revert if caller already has a Chainlink request in-flight for the pack", async () => {
      // Fund `Pack` with LINK
      await fundPack();

      // Open Pack (request)
      await pack.connect(creator).openPack(expectedPackId);

      // Open pack again, before the earlier request is fulfilled
      await expect(pack.connect(creator).openPack(expectedPackId)).to.be.revertedWith(
        "Pack: must wait for the pending pack to be opened.",
      );
    });
  });

  describe("Events", function () {
    it("Should emit PackOpenRequest", async () => {
      // Fund `Pack` with LINK
      await fundPack();

      expect(await pack.connect(creator).openPack(expectedPackId)).to.emit(pack, "PackOpenRequest");
    });
  });

  describe("Balances", function () {
    it("Should burn one pack of the caller", async () => {
      // Fund `Pack` with LINK
      await fundPack();

      const balBefore: BigNumber = await pack.balanceOf(await creator.getAddress(), expectedPackId);
      await pack.connect(creator).openPack(expectedPackId);
      const balAfter: BigNumber = await pack.balanceOf(await creator.getAddress(), expectedPackId);

      expect(balBefore.sub(balAfter)).to.equal(BigNumber.from(1));
    });
  });

  describe("Contract state changes", function () {
    beforeEach(async () => {
      // Fund `Pack` with LINK
      await fundPack();
    });

    it("Should show the caller has a Chainlink call in-flight for the pack", async () => {
      await pack.connect(creator).openPack(expectedPackId);

      const isPending: boolean = (await pack.currentRequestId(expectedPackId, await creator.getAddress())) !== "";
      expect(isPending).to.equal(true);
    });

    it("Should store the random number request with the id and caller address", async () => {
      // Get request Id of the open pack request
      let requestId: BytesLike = "";
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

      const requestInfo = await pack.randomnessRequests(requestId);

      expect(requestInfo.packId).to.equal(expectedPackId);
      expect(requestInfo.opener).to.equal(await creator.getAddress());
    });
  });
});
