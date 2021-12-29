import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Types
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Log } from "@ethersproject/abstract-provider";
import { ControlDeployer, Forwarder, ProtocolControl, Registry } from "typechain";

use(solidity);

/**
 * We deply 2 clones of ProtocolControl, each having a different deployer. Both clones
 * implement the logic in ProtocolControl, but have different states.
 */

describe("Deploy proxies for ProtocolControl using ControlDeployer", function() {

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin_1: SignerWithAddress;
  let protocolAdmin_2: SignerWithAddress;

  // Contracts
  let forwarder: Forwarder;
  let registry: Registry;
  let controlDeployer: ControlDeployer;
  
  // ProtocolControl proxies
  let clone_1: ProtocolControl;
  let clone_1_URI = "clone_1_URI";

  let clone_2: ProtocolControl;
  let clone_2_URI = "clone_2_URI";

  before(async () => {

    // Get signers
    [protocolProvider, protocolAdmin_1, protocolAdmin_2] = await ethers.getSigners();

    // Deploy Forwarder
    forwarder = (await ethers
      .getContractFactory("Forwarder")
      .then(f => f.connect(protocolProvider).deploy())) as Forwarder;
    
    // Deploy ControlDeployer
    controlDeployer = (await ethers
      .getContractFactory("ControlDeployer")
      .then(f => f.connect(protocolProvider).deploy())) as ControlDeployer;
    
    // Deploy Registry
    registry = (await ethers.getContractFactory("Registry").then(f =>
      f.connect(protocolProvider).deploy(
        protocolProvider.address, // Protocol provider treasury.
        forwarder.address, // Forwarder address.
        controlDeployer.address, // ControlDeployer address.
      ),
    )) as Registry;

    // Grant `REGISTRY_ROLE` in ControlDeployer, to Registry.
    const REGISTRY_ROLE = await controlDeployer.REGISTRY_ROLE();
    await controlDeployer.connect(protocolProvider).grantRole(REGISTRY_ROLE, registry.address);
  })

  beforeEach(async () => {
    // Deploy first clone
    const clone_1_deployReceipt = await registry
      .connect(protocolAdmin_1)
      .deployProtocol(clone_1_URI)
      .then(tx => tx.wait());
    
    const clone_1_log = clone_1_deployReceipt.logs.find(
      x => x.topics.indexOf(registry.interface.getEventTopic("NewProtocolControl")) >= 0,
    );
    const clone_1_addr: string = registry.interface.parseLog(clone_1_log as Log).args.controlAddress;

    clone_1 = await ethers.getContractAt("ProtocolControl", clone_1_addr);

    // Deploy second clone
    const clone_2_deployReceipt = await registry
      .connect(protocolAdmin_2)
      .deployProtocol(clone_2_URI)
      .then(tx => tx.wait());
    
    const clone_2_log = clone_2_deployReceipt.logs.find(
      x => x.topics.indexOf(registry.interface.getEventTopic("NewProtocolControl")) >= 0,
    );
    const clone_2_addr: string = registry.interface.parseLog(clone_2_log as Log).args.controlAddress;
    
    clone_2 = await ethers.getContractAt("ProtocolControl", clone_2_addr);
  })

  it("Should initialize the two different clones to two different states", async () => {
    expect(await clone_1.contractURI()).to.equal(clone_1_URI);
    expect(await clone_2.contractURI()).to.equal(clone_2_URI);

    expect(await clone_1.registry()).to.equal(registry.address)
    expect(await clone_2.registry()).to.equal(registry.address)

    expect(await clone_1.royaltyTreasury()).to.equal(clone_1.address)
    expect(await clone_2.royaltyTreasury()).to.equal(clone_2.address)

    const DEFAULT_ADMIN_ROLE = await clone_1.DEFAULT_ADMIN_ROLE();

    expect(await clone_1.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin_1.address)).to.equal(true)
    expect(await clone_1.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin_2.address)).to.equal(false)
    expect(await clone_2.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin_2.address)).to.equal(true)
    expect(await clone_2.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin_1.address)).to.equal(false)
  })
})