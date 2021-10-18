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
  const SCALED_SHARES = 10000;

  let RoyaltyFactory: any;
  let deployRoyalty: any;
  let feeTreasury = "";
  let feeBps = -1;

  // Signers
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let forwarder: Forwarder;
  let registry: Registry;
  let protocolControl: ProtocolControl;
  let nft: NFT;

  // Network
  const networkName = "rinkeby";

  const iface = new ethers.utils.Interface(["event PayeeAdded(address account, uint256 shares)"]);

  before(async () => {
    // Fork rinkeby for testing
    await forkFrom(networkName);

    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolAdmin, creator, relayer] = signers;

    RoyaltyFactory = await ethers.getContractFactory("Royalty");
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolAdmin, networkName);
    registry = contracts.registry;
    protocolControl = contracts.protocolControl;
    forwarder = contracts.forwarder;
    nft = contracts.nft;

    feeBps = (await registry.getFeeBps(protocolControl.address)).toNumber();
    feeTreasury = await registry.treasury();

    deployRoyalty = async (payees: string[], shares: BigNumberish[]): Promise<Royalty> =>
      RoyaltyFactory.deploy(protocolControl.address, forwarder.address, "", payees, shares) as Promise<Royalty>;
  });

  describe("Initialize", function () {
    it("treasury and fees", async () => {
      expect(feeBps).to.be.equals(500);
      expect(feeTreasury).to.be.equals(protocolAdmin.address);
    });

    it("emits events on create", async () => {
      const payees = ["0x000000000000000000000000000000000000dEaD"];
      const shares = [1];
      const tx = await deployRoyalty(payees, shares);
      const receipt = await tx.deployTransaction.wait();
      const payeeAdded = receipt.logs.map((l: any) => iface.parseLog(l)).map((l: any) => l.args);
      expect(payeeAdded.length).to.be.equals(payees.length + 1);
      expect(payeeAdded[0].account).to.be.equals(payees[0]);
      expect(payeeAdded[1].account).to.be.equals(feeTreasury);

      const scaledShares = shares[0] * SCALED_SHARES;
      const scaledSharesFees = (scaledShares * feeBps) / MAX_BPS;
      const scaledSharesMinusFee = scaledShares - scaledSharesFees;
      expect(payeeAdded[0].shares.toNumber()).to.be.equals(scaledSharesMinusFee);
      expect(payeeAdded[1].shares.toNumber()).to.be.equals(scaledSharesFees);
    });

    it("multiple shares", async () => {
      const payees = [
        "0x000000000000000000000000000000000000dEaD",
        "0x00000000000000000000000000000000dEadDEaD",
        "0x0000000000000000000000000000deadDEaDdeAd",
      ];
      const shares = [1, 2, 3];
      const r = await deployRoyalty(payees, shares);
      expect(await r.totalShares()).to.be.equals((1 + 2 + 3) * SCALED_SHARES);

      let totalFees = 0;
      for (let i = 0; i < payees.length; i++) {
        const scaledShares = shares[i] * SCALED_SHARES;
        const scaledSharesFees = (scaledShares * feeBps) / MAX_BPS;
        const scaledSharesMinusFee = scaledShares - scaledSharesFees;
        totalFees += scaledSharesFees;
        expect((await r.shares(payees[i])).toNumber()).to.be.equals(scaledSharesMinusFee);
      }

      expect((await r.shares(feeTreasury)).toNumber()).to.be.equals(totalFees);
    });
  });

  describe("Set Protocol Control Treasury", function () {
    it("multiple shares", async () => {
      const payees = [
        "0x000000000000000000000000000000000000dEaD",
        "0x00000000000000000000000000000000dEadDEaD",
        "0x0000000000000000000000000000deadDEaDdeAd",
      ];
      const shares = [1, 2, 3];
      const r = await deployRoyalty(payees, shares);
      expect(r.address).to.not.be.empty;
      expect(protocolControl.setRoyaltyTreasury(r.address)).to.not.be.reverted;
    });

    it("invalid royalty", async () => {
      const payees = [
        "0x000000000000000000000000000000000000dEaD",
        "0x00000000000000000000000000000000dEadDEaD",
        "0x0000000000000000000000000000deadDEaDdeAd",
      ];
      const shares = [1, 2, 3];
      const cf = await ethers.getContractFactory("MockRoyaltyNoFees");
      const r = await cf.deploy(protocolControl.address, forwarder.address, "", payees, shares);
      expect(r.address).to.not.be.empty;
      expect(protocolControl.setRoyaltyTreasury(r.address)).to.be.revertedWith(
        "ProtocolControl: provider shares too low. <DOESNT WORK>",
      );
    });
  });
});
