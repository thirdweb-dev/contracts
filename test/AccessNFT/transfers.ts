// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { Forwarder } from "../../typechain/Forwarder";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContractsPermissioned";
import { getURIs, getAmounts } from "../../utils/tests/params";
import { forkFrom } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";
import { BigNumber, BytesLike } from "ethers";

describe("Token transfers under various conditions", function () {
  // Signers
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let fan: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let accessNft: AccessNFT;
  let forwarder: Forwarder;

  // Reward parameters
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getAmounts(rewardURIs.length);
  const zeroAddress: string = "0x0000000000000000000000000000000000000000";
  const emptyData: BytesLike = ethers.utils.toUtf8Bytes("");

  // Redeem Parameters
  const amountToRedeeem: number = 1;
  let rewardId: number = 1;
  let accessId: number = 0;

  // Network
  const networkName = "rinkeby";

  before(async () => {
    // Fork rinkeby for testing
    await forkFrom(networkName);

    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolAdmin, creator, fan, relayer] = signers;
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolAdmin, networkName);
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;

    // Grant Minter role to creator
    const MINTER_ROLE = await accessNft.MINTER_ROLE();
    await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

    // Create access NFTs: creator
    await sendGaslessTx(creator, forwarder, relayer, {
      from: creator.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("createAccessNfts", [
        rewardURIs,
        accessURIs,
        rewardSupplies,
        zeroAddress,
        emptyData,
      ]),
    });

    // Redeem access NFT: creator
    await sendGaslessTx(creator, forwarder, relayer, {
      from: creator.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("redeemToken", [rewardId, amountToRedeeem]),
    });
  });

  describe("Transferring unredeemed rewards", function () {
    it("Should transfer tokens amongst non-TRANSFER_ROLE signers when transfers are not restricted", async () => {
      const creatorBalBefore: BigNumber = await accessNft.balanceOf(creator.address, rewardId);
      expect(await accessNft.balanceOf(fan.address, rewardId)).to.equal(0);

      // Send reward: creator to fan
      await sendGaslessTx(creator, forwarder, relayer, {
        from: creator.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("safeTransferFrom", [
          creator.address,
          fan.address,
          rewardId,
          amountToRedeeem,
          ethers.utils.toUtf8Bytes(""),
        ]),
      });

      const creatorBalAfter: BigNumber = await accessNft.balanceOf(creator.address, rewardId);
      expect(await accessNft.balanceOf(fan.address, rewardId)).to.equal(amountToRedeeem);
      expect(creatorBalBefore.sub(creatorBalAfter)).to.equal(amountToRedeeem);
    });

    it("Should revert transfer if transfers are restricted, and no participant has TRANSFER_ROLE", async () => {
      // Restrict transfers: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setRestrictedTransfer", [true]),
      });

      await expect(
        accessNft
          .connect(creator)
          .safeTransferFrom(creator.address, fan.address, rewardId, amountToRedeeem, ethers.utils.toUtf8Bytes("")),
      ).to.be.revertedWith("AccessNFT: Transfers are restricted to TRANSFER_ROLE holders");
    });

    it("Should not revert transfer if transfers are restricted, but at least one participant has TRANSFER_ROLE", async () => {
      // Restrict transfers: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setRestrictedTransfer", [true]),
      });

      // Grant TRANSFER_ROLE to creator.
      const TRANSFER_ROLE: BytesLike = await accessNft.TRANSFER_ROLE();

      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("grantRole", [TRANSFER_ROLE, creator.address]),
      });

      await expect(
        accessNft
          .connect(creator)
          .safeTransferFrom(creator.address, fan.address, rewardId, amountToRedeeem, ethers.utils.toUtf8Bytes("")),
      ).to.not.be.reverted;
    });
  });

  describe("Transferring redeemed rewards / access rewards", function () {
    beforeEach(async () => {
      expect(await accessNft.balanceOf(creator.address, accessId)).to.equal(amountToRedeeem);
    });

    it("Should revert transfer if access rewards are not transferable at contract level", async () => {
      await expect(
        accessNft
          .connect(creator)
          .safeTransferFrom(creator.address, fan.address, accessId, amountToRedeeem, ethers.utils.toUtf8Bytes("")),
      ).to.be.revertedWith("AccessNFT: cannot transfer an access NFT that is redeemed");
    });

    it("Should not revert transfer if access rewards are transferable at contract level", async () => {
      // Set access rewards as transferable: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setAccessNftTransferability", [true]),
      });

      await expect(
        accessNft
          .connect(creator)
          .safeTransferFrom(creator.address, fan.address, accessId, amountToRedeeem, ethers.utils.toUtf8Bytes("")),
      ).to.not.be.reverted;
    });

    it("Should revert transfer if access rewards are transferable, but general transfers are restricted and participants have no TRANSFER_ROLE", async () => {
      // Set access rewards as transferable: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setAccessNftTransferability", [true]),
      });

      // Restrict transfers: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setRestrictedTransfer", [true]),
      });

      await expect(
        accessNft
          .connect(creator)
          .safeTransferFrom(creator.address, fan.address, accessId, amountToRedeeem, ethers.utils.toUtf8Bytes("")),
      ).to.be.revertedWith("AccessNFT: Transfers are restricted to TRANSFER_ROLE holders");
    });

    it("Should not revert transfer if access rewards are transferable, general transfers are restricted but at least one participant has TRANSFER_ROLE", async () => {
      // Set access rewards as transferable: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setAccessNftTransferability", [true]),
      });

      // Restrict transfers: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setRestrictedTransfer", [true]),
      });

      // Grant TRANSFER_ROLE to creator.
      const TRANSFER_ROLE: BytesLike = await accessNft.TRANSFER_ROLE();

      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("grantRole", [TRANSFER_ROLE, creator.address]),
      });

      await expect(
        accessNft
          .connect(creator)
          .safeTransferFrom(creator.address, fan.address, accessId, amountToRedeeem, ethers.utils.toUtf8Bytes("")),
      ).to.not.be.reverted;
    });
  });
});
