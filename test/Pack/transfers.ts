import { ethers } from "hardhat";
import { expect } from "chai";

// Contract Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { Pack } from "../../typechain/Pack";
import { Forwarder } from "../../typechain/Forwarder";

// Types
import { BytesLike } from "@ethersproject/bytes";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts } from "../../utils/tests/params";
import { forkFrom, impersonate } from "../../utils/tests/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";
import linkTokenABi from "../../abi/LinkTokenInterface.json";
import { chainlinkVars } from "../../utils/chainlink";

describe("Token transfers under various conditions", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let fan: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: Pack;
  let accessNft: AccessNFT;
  let forwarder: Forwarder;

  // Reward parameters
  const [packURI]: string[] = getURIs(1);
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getAmounts(rewardURIs.length);
  const openStartAndEnd: number = 0;
  const rewardsPerOpen: number = 1;

  // Token IDs
  let packId: number;

  // Params
  const amountToTransfer: number = 1;

  const createPack = async (
    _packCreator: SignerWithAddress,
    _rewardURIs: string[],
    _accessURIs: string[],
    _rewardAmounts: number[],
    _packAddress: string,
    _encodedParamsAsData: BytesLike,
  ) => {
    await sendGaslessTx(_packCreator, forwarder, relayer, {
      from: _packCreator.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("createAccessTokens", [
        _packAddress,
        _rewardURIs,
        _accessURIs,
        _rewardAmounts,
        _encodedParamsAsData,
      ]),
    });
  };

  const encodeParams = (packURI: string, secondsUntilOpenStart: number, rewardsPerOpen: number) => {
    return ethers.utils.defaultAbiCoder.encode(
      ["string", "uint256", "uint256"],
      [packURI, secondsUntilOpenStart, rewardsPerOpen],
    );
  };

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, creator, fan, relayer] = signers;
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    pack = contracts.pack;
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;

    // Get pack ID
    packId = parseInt((await pack.nextTokenId()).toString());

    // Grant MINTER_ROLE to creator
    const MINTER_ROLE = await accessNft.MINTER_ROLE();
    await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
    await pack.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

    // Create packs
    await createPack(
      creator,
      rewardURIs,
      accessURIs,
      rewardSupplies,
      pack.address,
      encodeParams(packURI, openStartAndEnd, rewardsPerOpen),
    );
  });

  describe("Transferring packs", function () {
    it("Should transfer tokens amongst non-TRANSFER_ROLE signers when transfers are not restricted", async () => {
      const creatorBalBefore: BigNumber = await pack.balanceOf(creator.address, packId);
      expect(await pack.balanceOf(fan.address, packId)).to.equal(0);

      // Send reward: creator to fan
      await sendGaslessTx(creator, forwarder, relayer, {
        from: creator.address,
        to: pack.address,
        data: pack.interface.encodeFunctionData("safeTransferFrom", [
          creator.address,
          fan.address,
          packId,
          amountToTransfer,
          ethers.utils.toUtf8Bytes(""),
        ]),
      });

      const creatorBalAfter: BigNumber = await pack.balanceOf(creator.address, packId);
      expect(await pack.balanceOf(fan.address, packId)).to.equal(1);
      expect(creatorBalBefore.sub(creatorBalAfter)).to.equal(1);
    });

    it("Should revert transfer if transfers are restricted, and no participant has TRANSFER_ROLE", async () => {
      // Restrict transfers: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: pack.address,
        data: pack.interface.encodeFunctionData("setRestrictedTransfer", [true]),
      });

      await expect(
        sendGaslessTx(creator, forwarder, relayer, {
          from: creator.address,
          to: pack.address,
          data: pack.interface.encodeFunctionData("safeTransferFrom", [
            creator.address,
            fan.address,
            packId,
            amountToTransfer,
            ethers.utils.toUtf8Bytes(""),
          ]),
        }),
      ).to.be.revertedWith("Pack: Transfers are restricted to TRANSFER_ROLE holders");
    });

    it("Should not revert transfer if transfers are restricted, but at least one participant has TRANSFER_ROLE", async () => {
      // Restrict transfers: protocol admin
      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: pack.address,
        data: pack.interface.encodeFunctionData("setRestrictedTransfer", [true]),
      });

      // Grant TRANSFER_ROLE to creator.
      const TRANSFER_ROLE: BytesLike = await pack.TRANSFER_ROLE();

      await sendGaslessTx(protocolAdmin, forwarder, relayer, {
        from: protocolAdmin.address,
        to: pack.address,
        data: pack.interface.encodeFunctionData("grantRole", [TRANSFER_ROLE, creator.address]),
      });

      await expect(
        sendGaslessTx(creator, forwarder, relayer, {
          from: creator.address,
          to: pack.address,
          data: pack.interface.encodeFunctionData("safeTransferFrom", [
            creator.address,
            fan.address,
            packId,
            amountToTransfer,
            ethers.utils.toUtf8Bytes(""),
          ]),
        }),
      ).to.not.be.reverted;
    });
  });
});
