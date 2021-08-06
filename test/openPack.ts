import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BytesLike, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVarsMumbai } from "../utils/chainlink";
// import { forkFrom } from "../utils/mainnetFork";

describe("Testing openPack", function() {

  // Signers
  let protocolAdmin: Signer;
  let creator: Signer;

  // Contracts
  let rewards: Contract;
  let pack: Contract

  // Reward parameterrs
  const rewardURIs: string[] = [
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3"
  ]
  const rewardSupplies: number[] = [5, 10, 20];
  const rewardIds: number[] = [0, 1, 2]

  // Pack parameters
  const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const openStartAndEnd: number = 0;
  const packId: number = 0;
  const packSupply: number = 35;

  before(async () => {
    console.log("Hello 1");
    // Fork Mumbai
    // await forkFrom(17304936);
    console.log("Hello 2");

    [protocolAdmin, creator] = await ethers.getSigners();

    // Deploy Rewardds.sol and create rewards
    const Rewards_factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewards = await Rewards_factory.connect(creator).deploy();

    console.log("Hello 3");

    // Create rewards
    await rewards.connect(creator).createNativeRewards(rewardURIs, rewardSupplies);

    console.log("Hello 4");

    // Deploy $PACK Protocol
    const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMumbai;

    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    const controlCenter: Contract = await ProtocolControl_Factory.deploy(
      "$PACK Protocol",
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
    )

    console.log("Hello 5");

    const PACK: BytesLike = await controlCenter.PACK();
    const packAddress: string = await controlCenter.modules(PACK);
    pack = await ethers.getContractAt("Pack", packAddress);

    console.log("Hello 6");

    // Approve Pack to handle rewards
    await rewards.connect(creator).setApprovalForAll(packAddress, true);
  })

  it("Should open pack successfully", async () => {
    console.log("Hello 7");

    // Create pack
    await pack.connect(creator).createPack(
      packURI,
      rewards.address,
      rewardIds,
      rewardSupplies,
      openStartAndEnd,
      openStartAndEnd
    );

    console.log("Hello 8");

    expect(await pack.connect(creator).openPack(packId))
      .to.emit(pack, "PackOpenRequest")
  })
})