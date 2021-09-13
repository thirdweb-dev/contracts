import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BytesLike, BigNumber } from "ethers";
import { expect } from "chai";

import { forkFrom } from "../utils/hardhatFork";
import { chainlinkVars } from "../utils/chainlink";

describe("Deploying $PACK Protocol contracts and Rewards contract", function () {
  let deployer: Signer;
  let deployerAddress: string;

  // AccessControl roles.
  const PROTOCOL_ADMIN_ROLE: BytesLike = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("PROTOCOL_ADMIN"));

  before(async () => {
    // Fork rinkeby
    await forkFrom(9075707, "rinkeby");

    [deployer] = await ethers.getSigners();
    deployerAddress = await deployer.getAddress();
  });

  it("Should deploy the $PACK Protocol contracts and Rewards contract", async () => {
    // 1. Deploy ControlCenter
    const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
    const controlCenter: Contract = await ProtocolControl_Factory.deploy();

    // 2. Deploy protocol modules: `Pack` and `Market`
    const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars.rinkeby;
    const packTokenURI: string = "$PACK Protocol";

    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    const pack: Contract = await Pack_Factory.deploy(
      controlCenter.address,
      packTokenURI,
      vrfCoordinator,
      linkTokenAddress,
      keyHash,
      fees,
    );

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    const market: Contract = await Market_Factory.deploy(controlCenter.address);

    // Initialize $PACK Protocol in ControlCenter
    await controlCenter.initializeProtocol(pack.address, market.address);

    // Check whether the protocol has been initialized correctly.
    expect(await controlCenter.modules(await controlCenter.PACK())).to.equal(pack.address);

    expect(await controlCenter.modules(await controlCenter.MARKET())).to.equal(market.address);

    expect(await controlCenter.hasRole(PROTOCOL_ADMIN_ROLE, deployerAddress)).to.equal(true);

    // Deploy rewards contract.
    const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
    const rewards: Contract = await Rewards_Factory.deploy(pack.address);

    expect(await rewards.nextTokenId()).to.equal(0);
    expect(await rewards.pack()).to.equal(pack.address);
  });
});
