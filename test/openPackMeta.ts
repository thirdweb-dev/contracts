import { expect } from "chai";
import { ethers } from "hardhat";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom, impersonate } from "../utils/hardhatFork";
import linkTokenABi from "../abi/LinkTokenInterface.json";

import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const { signMetaTxRequest } = require("../utils/signer");

describe("Request to open a pack", function () {
  // Signers
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: Contract;
  let rewards: Contract;
  let forwarder: Contract;

  // Reward parameterrs
  const rewardURIs: string[] = [
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
  ];
  const rewardSupplies: number[] = [5, 25, 60];
  const rewardsPerOpen: number = 3;

  // Pack parameters
  const packURI: string = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const openStartAndEnd: number = 0;

  // Expected results
  const expectedPackId: number = 0;

  // Fund `Pack` with LINK
  const fundPack = async () => {
    const { linkTokenAddress } = chainlinkVars.rinkeby;

    const linkHolderAddress = "0xa7a82dd06901f29ab14af63faf3358ad101724a8";
    await impersonate(linkHolderAddress);
    const linkHolder = await ethers.getSigner(linkHolderAddress);

    const linkContract = await ethers.getContractAt(linkTokenABi, linkTokenAddress);
    linkContract.connect(linkHolder).transfer(pack.address, ethers.utils.parseEther("1"));
  };

  beforeEach(async () => {
    // Fork rinkeby
    await forkFrom(9075707, "rinkeby");

    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolAdmin, creator, relayer] = signers;

    // Deploy Forwarder
    const Forwarder_Factory: ContractFactory = await ethers.getContractFactory("Forwarder");
    forwarder = await Forwarder_Factory.deploy();

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
      forwarder.address,
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
    
    // Fund `Pack` with LINK
    await fundPack();
  });

  describe("Open pack - REGULAR transaction", function () {

    it("Should store the random number request with the id and caller address", async () => {
      // Get request Id of the open pack request
      let requestId = "";
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

  describe("Open pack - META transaction", function () {

    it("Should verify the meta tx", async () => {


      const packBalanceBefore = await pack.balanceOf(creator.address, expectedPackId);

      // Get request Id of the open pack request
      let requestId = "";
      const openPackPromise = new Promise((resolve, reject) => {
        pack.on("PackOpenRequest", (_packId, _caller, _requestId) => {
          requestId = _requestId;

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: PackOpenRequest"));
        }, 5000);
      });

      // Meta tx setup
      const { request, signature } = await signMetaTxRequest(creator.provider, forwarder, {
        from: creator.address,
        to: pack.address,
        data: pack.interface.encodeFunctionData("openPack", [
          ethers.utils.defaultAbiCoder.encode(["uint256"], [0]).slice(2),
        ]),
      });

      await forwarder.connect(relayer).execute(request, signature);
      await openPackPromise;

      const requestInfo = await pack.randomnessRequests(requestId);

      expect(requestInfo.packId).to.equal(expectedPackId);
      expect(requestInfo.opener).to.equal(await creator.getAddress());

      const packBalanceAfter = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceBefore.sub(packBalanceAfter)).to.equal(1);
    });
  });
});
