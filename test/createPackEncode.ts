import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom } from "../utils/hardhatFork";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BytesLike } from "ethers";

describe("Create a pack with rewards in a single tx", function () {
  // Signers
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;

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

    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolAdmin, creator] = signers;

    // deploy forwarder
    const Forwarder_factory = await ethers.getContractFactory("Forwarder");
    const forwarder = await Forwarder_factory.deploy()

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
      forwarder.address
    );

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    const market: Contract = await Market_Factory.deploy(controlCenter.address);

    await controlCenter.initializeProtocol(pack.address, market.address);

    // Deploy Rewards.sol and create rewards
    const Rewards_factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewards = await Rewards_factory.connect(creator).deploy(pack.address);
    // Create rewards
    await rewards
    .connect(creator)
    .createNativeRewards(rewardURIs, rewardSupplies);
  });

  describe("Balances", function () {

    it("Should mint the total supply of packs to the creator", async () => {

      // Encoded arguments
      const abiCoder = ethers.utils.defaultAbiCoder;
      const args: BytesLike = abiCoder.encode(
        ["string", "address", "uint256", "uint256", "uint256"],
        [packURI, rewards.address, openStartAndEnd, openStartAndEnd, rewardsPerOpen]
      );

      // Safe transfer with args
      await rewards.connect(creator).safeBatchTransferFrom(creator.address, pack.address, expectedRewardIds, rewardSupplies, args);

      expect(await pack.balanceOf(await creator.getAddress(), 0)).to.equal(expectedPackSupply);
    });
  });
});
