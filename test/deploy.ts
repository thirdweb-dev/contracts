import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BytesLike, BigNumber } from "ethers";
import { expect } from "chai";

import { chainlinkVarsRinkeby } from "../utils/chainlink";

describe("Deploying $PACK Protocol contracts", function() {

  let deployer: Signer;
  let deployerAddress: string;

  // AccessControl roles.
  const MINTER_ROLE: BytesLike = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("MINTER_ROLE")
  )
  const PAUSER_ROLE: BytesLike = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("PAUSER_ROLE")
  )
  const PROTOCOL_ADMIN_ROLE: BytesLike = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("PROTOCOL_ADMIN")
  );

  before(async () => {
    [deployer] = await ethers.getSigners()
    deployerAddress = await deployer.getAddress();
  })

  it("Should deploy the $PACK Protocol contracts", async () => {
    // 1. Deploy ControlCenter
    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    const controlCenter: Contract = await ProtocolControl_Factory.deploy(deployerAddress);

    // 2. Deploy rest of the protocol modules.
    const packTokenURI: string = "$PACK Protocol"
    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    const pack: Contract = await Pack_Factory.deploy(controlCenter.address, packTokenURI);

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    const market: Contract = await Market_Factory.deploy(controlCenter.address);

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVarsRinkeby;
    const fees: BigNumber = ethers.utils.parseEther("0.1");
    
    const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
    const rng: Contract = await RNG_Factory.deploy(
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
    
    // Check whether the protocol has been initialized correctly.
    expect(
      await controlCenter.getModule(await controlCenter.PACK())
    ).to.equal(pack.address)

    expect(
      await controlCenter.getModule(await controlCenter.MARKET())
    ).to.equal(market.address)

    expect(
      await controlCenter.getModule(await controlCenter.RNG())
    ).to.equal(rng.address)

    expect(await controlCenter.hasRole(PROTOCOL_ADMIN_ROLE, deployerAddress)).to.equal(true);
  })

  it("Should deploy the Access Packs contracts", async () => {

    const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    const rewards: Contract = await Rewards_Factory.deploy();

    expect(await rewards.hasRole(MINTER_ROLE, deployerAddress)).to.equal(true);
    expect(await rewards.hasRole(PAUSER_ROLE, deployerAddress)).to.equal(true);
  })
})