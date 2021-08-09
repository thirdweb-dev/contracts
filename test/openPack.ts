import { ethers, network } from "hardhat";
import { Signer, Contract, ContractFactory, BytesLike } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom, impersonate } from "../utils/hardhatFork";
import { setTimeout } from "timers";
import linkTokenABi from "../abi/LinkTokenInterface.json";

describe("Testing openPack", function() {

  // Signers
  let protocolAdmin: Signer;
  let creator: Signer;
  let vrf: Signer

  // Contracts
  let rewards: Contract;
  let pack: Contract

  // Reward parameterrs
  const rewardURIs: string[] = [
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3"
  ]
  const rewardSupplies: number[] = [5, 10, 20, 40, 80, 160, 320];
  const rewardIds: number[] = [0, 1, 2, 3, 4, 5, 6];

  // Pack parameters
  const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const openStartAndEnd: number = 0;
  const packId: number = 0;

  before(async () => {

    // Fork rinkeby
    await forkFrom(9075707, "rinkeby");

    const signers: Signer[] = await ethers.getSigners();
    [protocolAdmin, creator] = signers;

    // Deploy Rewardds.sol and create rewards
    const Rewards_factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewards = await Rewards_factory.connect(creator).deploy();

    // Create rewards
    await rewards.connect(creator).createNativeRewards(rewardURIs, rewardSupplies);

    // Deploy $PACK Protocol
    const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars.rinkeby;

    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    const controlCenter: Contract = await ProtocolControl_Factory.deploy()

    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    pack = await Pack_Factory.deploy(
      controlCenter.address,
      "$PACK Protocol",
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees
    )

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    const market: Contract = await Market_Factory.deploy(controlCenter.address);

    await controlCenter.initializeProtocol(pack.address, market.address);

    // Approve Pack to handle rewards
    await rewards.connect(creator).setApprovalForAll(pack.address, true);

    // Fund PACK with link
    const linkHolderAddress: string = "0xa7a82dd06901f29ab14af63faf3358ad101724a8";
    await impersonate(linkHolderAddress);
    const linkHolder: Signer = await ethers.getSigner(linkHolderAddress);

    const linkContract = await ethers.getContractAt(linkTokenABi, linkTokenAddress);
    linkContract.connect(linkHolder).transfer(pack.address, ethers.utils.parseEther("1"));

    // Impersonate VRF
    await impersonate(vrfCoordinator);
    vrf = await ethers.getSigner(vrfCoordinator);

    await network.provider.send("hardhat_setBalance", [
      vrfCoordinator,
      "0xDE0B6B3A7640000",
    ]);
  })

  it("Should open pack successfully", async () => {

    // Create pack
    await pack.connect(creator).createPack(
      packURI,
      rewards.address,
      rewardIds,
      rewardSupplies,
      openStartAndEnd,
      openStartAndEnd
    );

    // Open Pack
    let requestId: BytesLike = ethers.utils.toUtf8Bytes("");
    const randomNumber: number = 123461;

    const openPackPromise = new Promise((resolve, reject) => {
      pack.on("PackOpenRequest", (packId, caller, reqId) => {
        requestId = reqId;
        console.log(reqId)
        resolve(null);
      })

      setTimeout(() => {
        reject(new Error("Timeout: PackOpenRequest"));
      }, 10000);
    })

    await pack.connect(creator).openPack(packId)
    await openPackPromise

    const gastimate = await pack.connect(vrf).estimateGas.rawFulfillRandomness(requestId, randomNumber)
    console.log(parseInt(gastimate.toString()))
  })
})