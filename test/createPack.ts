import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/chainlink";
import { forkFrom } from "../utils/hardhatFork";


describe("Testing createPack", function() {

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

  // Pack parameters
  const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const openStartAndEnd: number = 0;

  before(async () => {

    // Fork rinkeby
    await forkFrom(9075707, "rinkeby");

    const signers: Signer[] = await ethers.getSigners();
    [protocolAdmin, creator] = signers;

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

    // Deploy Rewardds.sol and create rewards
    const Rewards_factory: ContractFactory = await ethers.getContractFactory("Rewards");
    rewards = await Rewards_factory.connect(creator).deploy(pack.address);
  })

  it("Should create a pack successfully", async () => {

    const gasEst = await rewards.estimateGas.createPack(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd)

    console.log("Gas to create pack: ", parseInt(gasEst.toString()))

    expect(await rewards.createPack(rewardURIs, rewardSupplies, packURI, openStartAndEnd, openStartAndEnd))
      .to.emit(pack, "PackCreated")
  })
})