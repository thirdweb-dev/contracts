// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFTPL } from "../../typechain/AccessNFTPL";
import { PackPL } from "../../typechain/PackPL";
import { Forwarder } from "../../typechain/Forwarder";
import { BytesLike } from "@ethersproject/bytes";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts } from "../../utils/tests/params";
import { forkFrom, impersonate } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";
import linkTokenABi from "../../abi/LinkTokenInterface.json";
import { chainlinkVars } from "../../utils/chainlink";

describe("Token transfers under various conditions", function () {
  // Signers
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let fan: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: PackPL;
  let accessNft: AccessNFTPL;
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
  let rewardIds: number[];

  // Network
  const networkName = "rinkeby";

  const createPack = async (
    _packCreator: SignerWithAddress,
    _rewardIds: number[],
    _rewardAmounts: number[],
    _encodedParamsAsData: BytesLike
  ) => {

    await sendGaslessTx(
      _packCreator,
      forwarder,
      relayer,
      {
        from: _packCreator.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("safeBatchTransferFrom", [
          _packCreator.address,
          pack.address,
          _rewardIds,
          _rewardAmounts,
          _encodedParamsAsData
        ])
      }
    )
  }

  const encodeParams = (packURI: string, secondsUntilOpenStart: number, secondsUntilOpenEnd: number, rewardsPerOpen: number) => {
    return ethers.utils.defaultAbiCoder.encode(
      ["string", "uint256", "uint256", "uint256"],
      [packURI, secondsUntilOpenStart, secondsUntilOpenEnd, rewardsPerOpen]
    );
  }

  // Fund `Pack` with LINK
  const fundPack = async () => {
    const { linkTokenAddress } = chainlinkVars[networkName];

    const linkHolderAddress: string = "0xa7a82dd06901f29ab14af63faf3358ad101724a8";
    await impersonate(linkHolderAddress);
    const linkHolder: SignerWithAddress = await ethers.getSigner(linkHolderAddress);

    const linkContract = await ethers.getContractAt(linkTokenABi, linkTokenAddress);
    linkContract.connect(linkHolder).transfer(pack.address, ethers.utils.parseEther("1"));
  };

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
    pack = contracts.pack;
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;

    // Create Access NFTs as rewards
    await sendGaslessTx(
      creator,
      forwarder,
      relayer,
      {
        from: creator.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("createAccessNfts", [
          rewardURIs,
          accessURIs,
          rewardSupplies
        ])
      }
    )

    // Get pack ID
    packId = parseInt((await pack.nextTokenId()).toString());

    // Get rewardIds
    const nextAccessNftId: number = parseInt((await accessNft.nextTokenId()).toString());
    const expectedRewardIds: number[] = [];
    for (let val of [...Array(nextAccessNftId).keys()]) {
      if (val % 2 != 0) {
        expectedRewardIds.push(val);
      }
    }

    rewardIds = expectedRewardIds;

    // Create packs
    await createPack(
      creator,
      rewardIds,
      rewardSupplies,
      encodeParams(packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen)
    );

    // Fund pack contract with LINK
    await fundPack();
  })

  describe("Transferring packs", function() {

    it("Should transfer tokens amongst non-TRANSFER_ROLE signers when transfers are not restricted", async () => {

      const creatorBalBefore: BigNumber = await pack.balanceOf(creator.address, packId);
      expect(await pack.balanceOf(fan.address, packId)).to.equal(0);

      // Send reward: creator to fan
      await sendGaslessTx(
        creator,
        forwarder,
        relayer,
        {
          from: creator.address,
          to: pack.address,
          data: pack.interface.encodeFunctionData("safeTransferFrom", [
            creator.address, fan.address, packId, 1, ethers.utils.toUtf8Bytes("")
          ])
        }
      )

      const creatorBalAfter: BigNumber = await pack.balanceOf(creator.address, packId);
      expect(await pack.balanceOf(fan.address, packId)).to.equal(1);
      expect(creatorBalBefore.sub(creatorBalAfter)).to.equal(1);
    })

    it("Should revert transfer if transfers are restricted, and no participant has TRANSFER_ROLE", async () => {

      // Restrict transfers: protocol admin
      await sendGaslessTx(
        protocolAdmin,
        forwarder,
        relayer,
        {
          from: protocolAdmin.address,
          to: pack.address,
          data: pack.interface.encodeFunctionData("setRestrictedTransfer", [true])
        }
      )

      await expect(
        pack.connect(creator).safeTransferFrom(
          creator.address,
          fan.address,
          packId,
          1,
          ethers.utils.toUtf8Bytes("")
        )
      ).to.be.revertedWith("Pack: Transfers are restricted to TRANSFER_ROLE holders");
    })

    it("Should not revert transfer if transfers are restricted, but at least one participant has TRANSFER_ROLE", async () => {

      // Restrict transfers: protocol admin
      await sendGaslessTx(
        protocolAdmin,
        forwarder,
        relayer,
        {
          from: protocolAdmin.address,
          to: pack.address,
          data: pack.interface.encodeFunctionData("setRestrictedTransfer", [true])
        }
      )

      // Grant TRANSFER_ROLE to creator.
      const TRANSFER_ROLE: BytesLike = await pack.TRANSFER_ROLE();

      await sendGaslessTx(
        protocolAdmin,
        forwarder,
        relayer,
        {
          from: protocolAdmin.address,
          to: pack.address,
          data: pack.interface.encodeFunctionData("grantRole", [TRANSFER_ROLE, creator.address])
        }
      )


      await expect(
        pack.connect(creator).safeTransferFrom(
          creator.address,
          fan.address,
          packId,
          1,
          ethers.utils.toUtf8Bytes("")
        )
      ).to.not.be.reverted;
    })
  })
});