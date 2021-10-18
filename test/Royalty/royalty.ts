// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { Pack } from "../../typechain/Pack";
import { Forwarder } from "../../typechain/Forwarder";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, BigNumberish } from "ethers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts } from "../../utils/tests/params";
import { forkFrom, impersonate } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";
import { Registry } from "../../typechain/Registry";
import { Royalty } from "../../typechain";
import { ProtocolControl } from "../../typechain/ProtocolControl";
import { NFT } from "../../typechain/NFT";

describe("Royalty", function () {
  const MAX_BPS = 10000;
  const SCALE_FACTOR = 10000;
  const defaultFeeBps = 500; // 5%

  let RoyaltyFactory: any;
  let deployRoyalty: any;
  let feeTreasury = "";
  let feeBps = -1;

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let forwarder: Forwarder;
  let registry: Registry;
  let protocolControl: ProtocolControl;

  // Test parameters
  const singlePayee: string = "0x000000000000000000000000000000000000dEaD";
  const multiplePayees: string[] = [
    "0x000000000000000000000000000000000000dEaD",
    "0x00000000000000000000000000000000dEadDEaD",
    "0x0000000000000000000000000000deadDEaDdeAd",
  ];

  // Network
  const payeeAddedInterface = new ethers.utils.Interface(["event PayeeAdded(address account, uint256 shares)"]);

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, creator, relayer] = signers;

    // Get contract factory.
    RoyaltyFactory = await ethers.getContractFactory("Royalty");
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    registry = contracts.registry;
    protocolControl = contracts.protocolControl;
    forwarder = contracts.forwarder;

    feeBps = (await registry.getFeeBps(protocolControl.address)).toNumber();
    feeTreasury = await registry.treasury();

    deployRoyalty = async (payees: string[], shares: BigNumberish[]): Promise<Royalty> =>
      RoyaltyFactory.deploy(protocolControl.address, forwarder.address, "", payees, shares) as Promise<Royalty>;
  });

  // describe("Default state of fees", function() {
  //   it("Should initially return default fee bps and treasury", async () => {
  //     expect(feeBps).to.be.equals(defaultFeeBps);
  //     expect(feeTreasury).to.be.equals(protocolProvider.address);
  //   });
  // })

  // describe("Default state of Royalty contract", function () {

  //   it("Emits, for each payee, PayeeAdded with payee address and shares on creation", async () => {
  //     // Set payes and shares
  //     const payees = [singlePayee];
  //     const shares = [1];
      
  //     // Deploy Royalty
  //     const royaltyContract: Royalty = await deployRoyalty(payees, shares);
  //     const receipt = await royaltyContract.deployTransaction.wait();
      
  //     // Get PayeeAdded events emitted.
  //     const payeeAdded = receipt.logs.map((l: any) => payeeAddedInterface.parseLog(l)).map((l: any) => l.args);

  //     expect(payeeAdded.length).to.be.equals(payees.length + 1); // All payess + registry treasury.
  //     expect(payeeAdded[0].account).to.be.equals(payees[0]);
  //     expect(payeeAdded[1].account).to.be.equals(feeTreasury);

  //     const scaledShares = shares[0] * SCALE_FACTOR;
  //     const scaledSharesFees = (scaledShares * feeBps) / MAX_BPS;
  //     const scaledSharesMinusFee = scaledShares - scaledSharesFees;

  //     expect(payeeAdded[0].shares.toNumber()).to.be.equals(scaledSharesMinusFee);
  //     expect(payeeAdded[1].shares.toNumber()).to.be.equals(scaledSharesFees);
  //   });

  //   it("Should store the right shares on the contract", async () => {
  //     const payees = multiplePayees;
  //     const shares = [1, 2, 3];

  //     // Deploy Royalty
  //     const royaltyContract: Royalty = await deployRoyalty(payees, shares);

  //     expect(await royaltyContract.totalShares()).to.be.equals((1 + 2 + 3) * SCALE_FACTOR);

  //     let totalFees = 0;
  //     for (let i = 0; i < payees.length; i++) {

  //       // Get share split
  //       const scaledShares = shares[i] * SCALE_FACTOR;
  //       const scaledSharesFees = (scaledShares * feeBps) / MAX_BPS;
  //       const scaledSharesMinusFee = scaledShares - scaledSharesFees;
        
  //       // Update fees
  //       totalFees += scaledSharesFees;

  //       // Check shares for payees;
  //       expect((await royaltyContract.shares(payees[i])).toNumber()).to.be.equals(scaledSharesMinusFee);
  //     }

  //     // Check shares for protocol provider i.e. at this point, registry treasury.
  //     expect((await royaltyContract.shares(feeTreasury)).toNumber()).to.be.equals(totalFees);
  //   });
  // });

  describe("Set Protocol Control Treasury", function () {
    it("Should allow setting a valid Royalty contract", async () => {

      // Set payes and shares
      const payees = multiplePayees;
      const shares = [1, 2, 3];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be.reverted;
    });

    it("Should revert if setting an invalid Royalty contract", async () => {
      
      // Set payes and shares
      const payees = multiplePayees;
      const shares = [1, 2, 3];

      const invalidRoyaltyContract = await ethers.getContractFactory("MockRoyaltyNoFees").then(f => f.connect(protocolAdmin).deploy(
        protocolControl.address, forwarder.address, "", payees, shares
      ))
      
      expect(invalidRoyaltyContract.address).to.not.be.empty;

      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(invalidRoyaltyContract.address)).to.be.revertedWith(
        "ProtocolControl: provider shares too low.",
      );
    });
  });
});
