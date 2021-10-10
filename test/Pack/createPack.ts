// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { Pack } from "../../typechain/Pack";
import { Forwarder } from "../../typechain/Forwarder";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts } from "../../utils/tests/params";
import { forkFrom } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";

describe("Create a pack with rewards", function () {
  // Signers
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
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

  // Network
  const networkName = "rinkeby";

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
    // Fork rinkeby for testing
    await forkFrom(networkName);

    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolAdmin, creator, relayer] = signers;
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolAdmin, networkName);
    pack = contracts.pack;
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;

    // Get pack ID
    packId = parseInt((await pack.nextTokenId()).toString());
  });

  describe("Revert", function () {
    it("Should revert if unequal number of URIs and supplies are provided", async () => {
      // Grant MINTER_ROLE to creator
      const MINTER_ROLE = await accessNft.MINTER_ROLE();
      await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
      await pack.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

      await expect(
        accessNft
          .connect(creator)
          .createAccessTokens(
            pack.address,
            rewardURIs.slice(1),
            accessURIs,
            rewardSupplies,
            encodeParams(packURI, openStartAndEnd, rewardsPerOpen),
          ),
      ).to.be.reverted;

      await expect(
        accessNft
          .connect(creator)
          .createAccessTokens(
            pack.address,
            rewardURIs,
            accessURIs.slice(1),
            rewardSupplies,
            encodeParams(packURI, openStartAndEnd, rewardsPerOpen),
          ),
      ).to.be.reverted;
    });

    it("Should revert if no NFTs are to be created", async () => {
      // Grant MINTER_ROLE to creator
      const MINTER_ROLE = await accessNft.MINTER_ROLE();
      await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
      await pack.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

      await expect(
        accessNft
          .connect(creator)
          .createAccessTokens(pack.address, [], [], [], encodeParams(packURI, openStartAndEnd, rewardsPerOpen)),
      ).to.be.reverted;
    });

    it("Should revert if caller does not have MINTER_ROLE", async () => {
      await expect(
        accessNft
          .connect(creator)
          .createAccessTokens(
            pack.address,
            rewardURIs,
            accessURIs,
            rewardSupplies,
            encodeParams(packURI, openStartAndEnd, rewardsPerOpen),
          ),
      ).to.be.reverted;
    });

    it("Should revert if total supply of NFTs is not divisible by the number of NFTs to distribute on pack opening.", async () => {
      // Grant MINTER_ROLE to creator
      const MINTER_ROLE = await accessNft.MINTER_ROLE();
      await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
      await pack.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

      const invalidRewardsPerOpen = rewardSupplies.reduce((a, b) => a + b) - 1;

      await expect(
        accessNft
          .connect(creator)
          .createAccessTokens(
            pack.address,
            rewardURIs,
            accessURIs,
            rewardSupplies,
            encodeParams(packURI, openStartAndEnd, invalidRewardsPerOpen),
          ),
      ).to.be.revertedWith("Pack: invalid number of rewards per open.");
    });
  });

  describe("Events", function () {
    beforeEach(async () => {
      // Grant MINTER_ROLE to creator
      const MINTER_ROLE = await accessNft.MINTER_ROLE();
      await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
      await pack.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
    });

    it("Should emit PackCreated", async () => {
      const eventPromise = new Promise((resolve, reject) => {
        pack.on("PackCreated", async (_packId, _rewardContract, _creator, _packTotalSupply, _packState, _rewards) => {
          expect(_packId).to.equal(packId);
          expect(_rewardContract).to.equal(accessNft.address);
          expect(_creator).to.equal(creator.address);

          expect(_packState.uri).to.equal(packURI);
          expect(_packState.creator).to.equal(creator.address);

          expect(_packTotalSupply).to.equal(rewardSupplies.reduce((a, b) => a + b) / rewardsPerOpen);

          expect(_rewards.source).to.equal(accessNft.address);
          expect(_rewards.rewardsPerOpen).to.equal(rewardsPerOpen);

          expect(rewardURIs.length).to.equal(_rewards.tokenIds.length);
          expect(rewardURIs.length).to.equal(_rewards.amountsPacked.length);

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: PackCreated"));
        }, 5000);
      });

      await createPack(
        creator,
        rewardURIs,
        accessURIs,
        rewardSupplies,
        pack.address,
        encodeParams(packURI, openStartAndEnd, rewardsPerOpen),
      );

      await eventPromise;
    });
  });

  describe("Balances", async () => {
    let rewardIds: number[];

    beforeEach(async () => {
      // Grant MINTER_ROLE to creator
      const MINTER_ROLE = await accessNft.MINTER_ROLE();
      await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
      await pack.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

      await createPack(
        creator,
        rewardURIs,
        accessURIs,
        rewardSupplies,
        pack.address,
        encodeParams(packURI, openStartAndEnd, rewardsPerOpen),
      );

      // Get rewardIds
      const nextAccessNftId: number = parseInt((await accessNft.nextTokenId()).toString());
      const expectedRewardIds: number[] = [];
      for (let val of [...Array(nextAccessNftId).keys()]) {
        if (val % 2 != 0) {
          expectedRewardIds.push(val);
        }
      }

      rewardIds = expectedRewardIds;
    });

    it("Should mint all unredeemed access NFTs to the pack contract", async () => {
      expect(rewardIds.length).to.equal(rewardSupplies.length);

      for (let i = 0; i < rewardSupplies.length; i++) {
        expect(await accessNft.balanceOf(pack.address, rewardIds[i])).to.equal(rewardSupplies[i]);
      }
    });

    it("Should mint all packs to the creator", async () => {
      expect(await pack.balanceOf(creator.address, packId)).to.equal(
        rewardSupplies.reduce((a, b) => a + b) / rewardsPerOpen,
      );
    });
  });

  describe("Contract state", function () {
    let rewardIds: number[];

    beforeEach(async () => {
      // Grant MINTER_ROLE to creator
      const MINTER_ROLE = await accessNft.MINTER_ROLE();
      await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);
      await pack.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

      await createPack(
        creator,
        rewardURIs,
        accessURIs,
        rewardSupplies,
        pack.address,
        encodeParams(packURI, openStartAndEnd, rewardsPerOpen),
      );

      // Get rewardIds
      const nextAccessNftId: number = parseInt((await accessNft.nextTokenId()).toString());
      const expectedRewardIds: number[] = [];
      for (let val of [...Array(nextAccessNftId).keys()]) {
        if (val % 2 != 0) {
          expectedRewardIds.push(val);
        }
      }

      rewardIds = expectedRewardIds;
    });

    it("Should store the state of the packs just created", async () => {
      const packState = await pack.getPackWithRewards(packId);

      expect(packState.pack.uri).to.equal(packURI);
      expect(packState.pack.creator).to.equal(creator.address);

      expect(await pack.totalSupply(packId)).to.equal(rewardSupplies.reduce((a, b) => a + b) / rewardsPerOpen);

      expect(packState.source).to.equal(accessNft.address);
      expect(rewardIds.length).to.equal(packState.tokenIds.length);
      expect(rewardSupplies.length).to.equal(packState.amountsPacked.length);

      for (let i = 0; i < rewardIds.length; i++) {
        expect(rewardIds[i]).to.equal(packState.tokenIds[i]);
        expect(rewardSupplies[i]).to.equal(packState.amountsPacked[i]);
      }
    });
  });
});
