import hre, { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Types
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Log } from "@ethersproject/abstract-provider";
import { Coin, ControlDeployer, ProtocolControl, Registry } from "typechain";
import { getContracts } from "../../utils/tests/getContracts";
import { BigNumber } from "ethers";

// Utils
import { forkFrom, impersonate } from "../../utils/tests/hardhatFork";

use(solidity);

/**
 * We fork a chain on which Registry is deployed. Then, we deploy the new version
 * of ControlDeployer and point Registry to this new version. 
 */

describe("Fork a chain and deploy the new ProtocolControl pattern", async () => {
  
  // Constants
  const registryAddresses: string = "0x902a29f2cfe9f8580ad672AaAD7E917d85ca9a2E";

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin_1: SignerWithAddress;
  let protocolAdmin_2: SignerWithAddress;

  // Contracts
  let registry: Registry;
  let controlDeployer: ControlDeployer;
  
  // ProtocolControl proxies
  let clone_1: ProtocolControl;
  let clone_1_URI = "clone_1_URI";

  let clone_2: ProtocolControl;
  let clone_2_URI = "clone_2_URI";

  // Impersonate Registry owner
  const impersonateAccount = async (owner: string): Promise<SignerWithAddress> => {

    // Impersonate VRF
    await impersonate(owner);
    const registryOwner = await ethers.getSigner(owner);

    await hre.network.provider.send("hardhat_setBalance", [registryOwner.address, "0xDE0B6B3A7640000"]);

    return registryOwner;
  };

  before(async () => {
    /**
     * The block number passed must be greater than the deploy block of registry
     * on that network.
     * 
     * The network name is hardcoded. Ideally, we use `hre.networ.name` with the
     * network pased as `npx hardhat test ... --network [network name]`. However,
     * the program bugs out in that case (need to figure out why).
     */
    await forkFrom("rinkeby", 9491930);

    // Get Registry and Forwarder
    registry = await ethers.getContractAt("Registry", registryAddresses);

    // Get signers
    const registryOwner: string = await registry.owner()
    protocolProvider = await impersonateAccount(registryOwner);
    [protocolAdmin_1, protocolAdmin_2] = await ethers.getSigners();
    
    // Deploy ControlDeployer
    controlDeployer = (await ethers
      .getContractFactory("ControlDeployer")
      .then(f => f.connect(protocolProvider).deploy())) as ControlDeployer;

    // Grant `REGISTRY_ROLE` in ControlDeployer, to Registry.
    const REGISTRY_ROLE = await controlDeployer.REGISTRY_ROLE();
    await controlDeployer.connect(protocolProvider).grantRole(REGISTRY_ROLE, registry.address);

    // Point Registry to the new ControlDeployer
    await registry.connect(protocolProvider).setDeployer(controlDeployer.address);
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

  it("Should set the newly deployed ControlDeployer in Registry", async () => {
    expect(await registry.deployer()).to.equal(controlDeployer.address)
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

  it("Should prevent initializing a clone after deployment", async () => {
    await expect(
      clone_1.connect(protocolProvider).initialize(
        registry.address,
        protocolProvider.address,
        clone_1_URI
      )
    ).to.be.revertedWith("Initializable: contract is already initialized")

    await expect(
      clone_2.connect(protocolProvider).initialize(
        registry.address,
        protocolProvider.address,
        clone_1_URI
      )
    ).to.be.revertedWith("Initializable: contract is already initialized")

  })

  describe("Test the withdrawal of funds from the clones", function() {
    
    // This works with: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" and address(0);
    // const NATIVE_TOKEN_ADDRESS: string = ethers.constants.AddressZero;
    const NATIVE_TOKEN_ADDRESS: string = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

    // Additional signers
    let erc20Signer: SignerWithAddress;
    let fundsReceiver: SignerWithAddress;

    // ERC20 token contract
    let erc20Token: Coin;

    // Test params
    const amountToSendToClones: BigNumber = ethers.utils.parseEther("10");

    // Sadly, just `before` refuses to work.
    beforeEach(async () => {
      // Get ERC20 signer
      [erc20Signer, fundsReceiver] = (await ethers.getSigners()).slice(5);

      // Get ERC20 token
      const contracts = await getContracts(protocolProvider, erc20Signer);
      erc20Token = contracts.coin;

      // Mint ERC20 tokens to clones
      await erc20Token.connect(erc20Signer).mint(clone_1.address, amountToSendToClones);

      // Send ether to clones
      await erc20Signer.sendTransaction({
        to: clone_1.address,
        value: amountToSendToClones
      })
    })

    it("Should allow withdrawing native token from clones", async () => {
      const fundsReceiverBalBefore: BigNumber = await ethers.provider.getBalance(fundsReceiver.address);
      const registryTreasuryBalBefore: BigNumber = await ethers.provider.getBalance(await registry.treasury());

      await clone_1.connect(protocolAdmin_1).withdrawFunds(fundsReceiver.address, NATIVE_TOKEN_ADDRESS);

      const MAX_BPS: BigNumber = await clone_1.MAX_BPS();
      const registryFeeBps: BigNumber = await registry.getFeeBps(clone_1.address);
      const registryFee: BigNumber = (amountToSendToClones.mul(registryFeeBps)).div(MAX_BPS);

      const fundsReceiverBalAfter: BigNumber = await ethers.provider.getBalance(fundsReceiver.address);
      const registryTreasuryBalAfter: BigNumber = await ethers.provider.getBalance(await registry.treasury());

      expect(fundsReceiverBalAfter).to.equal(fundsReceiverBalBefore.add(amountToSendToClones.sub(registryFee)));
      expect(registryTreasuryBalAfter).to.equal(registryTreasuryBalBefore.add(registryFee));
    })

    it("Should allow withdrawing ERC20 token from clones", async () => {
      const fundsReceiverBalBefore: BigNumber = await erc20Token.balanceOf(fundsReceiver.address);
      const registryTreasuryBalBefore: BigNumber = await erc20Token.balanceOf(await registry.treasury());

      await clone_1.connect(protocolAdmin_1).withdrawFunds(fundsReceiver.address, erc20Token.address);

      const MAX_BPS: BigNumber = await clone_1.MAX_BPS();
      const registryFeeBps: BigNumber = await registry.getFeeBps(clone_1.address);
      const registryFee: BigNumber = (amountToSendToClones.mul(registryFeeBps)).div(MAX_BPS);

      const fundsReceiverBalAfter: BigNumber = await erc20Token.balanceOf(fundsReceiver.address);
      const registryTreasuryBalAfter: BigNumber = await erc20Token.balanceOf(await registry.treasury());

      expect(fundsReceiverBalAfter).to.equal(fundsReceiverBalBefore.add(amountToSendToClones.sub(registryFee)));
      expect(registryTreasuryBalAfter).to.equal(registryTreasuryBalBefore.add(registryFee));
    })
  })
})