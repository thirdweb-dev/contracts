import { ethers } from "hardhat";
import { Signer, Contract, ContractFactory, BytesLike } from "ethers";
import { expect } from "chai";

import { chainlinkVars } from "../utils/utils";

describe("Deploying $PACK Protocol and Access Packs contracts", function() {

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
    const ControlCenter_Factory: ContractFactory = await ethers.getContractFactory("ControlCenter");
    const controlCenter: Contract = await ControlCenter_Factory.deploy(deployerAddress);

    // 2. Deploy rest of the protocol modules.
    const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
    const pack: Contract = await Pack_Factory.deploy(controlCenter.address);

    const Handler_Factory: ContractFactory = await ethers.getContractFactory("Handler");
    const handler: Contract = await Handler_Factory.deploy(controlCenter.address);

    const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
    const market: Contract = await Market_Factory.deploy(controlCenter.address);

    const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVars;
    
    const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
    const rng: Contract = await RNG_Factory.deploy(
      controlCenter.address,
      vrfCoordinator,
      linkTokenAddress,
      keyHash
    );

    const AssetSafe_Factory: ContractFactory = await ethers.getContractFactory("AssetSafe");
    const assetSafe: Contract = await AssetSafe_Factory.deploy(controlCenter.address);

    // Initialize $PACK Protocol in ControlCenter
    await controlCenter.initPackProtocol(
      pack.address,
      handler.address,
      market.address,
      rng.address,
      assetSafe.address
    );
    
    // Check whether the protocol has been initialized correctly.
    expect(
      await controlCenter.getModule(await controlCenter.PACK())
    ).to.equal(pack.address)

    expect(
      await controlCenter.getModule(await controlCenter.HANDLER())
    ).to.equal(handler.address)

    expect(
      await controlCenter.getModule(await controlCenter.MARKET())
    ).to.equal(market.address)

    expect(
      await controlCenter.getModule(await controlCenter.RNG())
    ).to.equal(rng.address)

    expect(
      await controlCenter.getModule(await controlCenter.ASSET_SAFE())
    ).to.equal(assetSafe.address)

    // Grant MINTER_ROLE in `Pack` to `Handler`
    await controlCenter.grantRoleERC1155(MINTER_ROLE, handler.address);

    const DEFAULT_ADMIN_ROLE: BytesLike = await controlCenter.DEFAULT_ADMIN_ROLE();

    // Check AccessControl rights
    expect(await pack.hasRole(MINTER_ROLE, deployerAddress)).to.equal(false);
    expect(await pack.hasRole(PAUSER_ROLE, deployerAddress)).to.equal(false);
    expect(await pack.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress)).to.equal(false);

    expect(await pack.hasRole(MINTER_ROLE, handler.address)).to.equal(true);
    expect(await pack.hasRole(PAUSER_ROLE, handler.address)).to.equal(false);
    expect(await pack.hasRole(DEFAULT_ADMIN_ROLE, handler.address)).to.equal(false);

    expect(await pack.hasRole(MINTER_ROLE, controlCenter.address)).to.equal(false);
    expect(await pack.hasRole(PAUSER_ROLE, controlCenter.address)).to.equal(true);
    expect(await pack.hasRole(DEFAULT_ADMIN_ROLE, controlCenter.address)).to.equal(true);

    expect(await controlCenter.hasRole(PROTOCOL_ADMIN_ROLE, deployerAddress)).to.equal(true);
  })

  it("Should deploy the Access Packs contracts", async () => {
    // 1. Deploy ControlCenter
    const ControlCenter_Factory: ContractFactory = await ethers.getContractFactory("ControlCenter");
    const controlCenter: Contract = await ControlCenter_Factory.deploy(deployerAddress);
    // ... Initialize pack protocol. Then:

    const AccessPacks_Factory: ContractFactory = await ethers.getContractFactory("AccessPacks");
    const accessPacks: Contract = await AccessPacks_Factory.deploy(controlCenter.address);

    // Check AccessControl rights
    const DEFAULT_ADMIN_ROLE: BytesLike = await controlCenter.DEFAULT_ADMIN_ROLE();

    expect(await accessPacks.hasRole(MINTER_ROLE, deployerAddress)).to.equal(false);
    expect(await accessPacks.hasRole(PAUSER_ROLE, deployerAddress)).to.equal(false);
    expect(await accessPacks.hasRole(DEFAULT_ADMIN_ROLE, deployerAddress)).to.equal(false);

    expect(await accessPacks.hasRole(DEFAULT_ADMIN_ROLE, controlCenter.address)).to.equal(false);
  })
})