// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFTPL } from "../typechain/AccessNFTPL";
import { PackPL } from "../typechain/PackPL";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../utils/tests/getContracts";
import { getURIs, getSupplies, openStartAndEnd, rewardsPerOpen } from "../utils/tests/params";

describe("Create a pack with rewards in a single tx", function () {
  // Signers
  let deployer: SignerWithAddress;
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: PackPL;
  let accessNft: AccessNFTPL;

  // Reward parameters
  const [packURI]: string[] = getURIs(1);
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getSupplies(rewardURIs.length);

  beforeEach(async () => {
    // Get signers
    const networkName: string = "mumbai";
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [deployer, creator, relayer] = signers;

    // Get contracts
    const contracts: Contracts = await getContracts(deployer, networkName);
    pack = contracts.pack;
    accessNft = contracts.accessNft;
  });

  describe("Revert", function () {
    it("Should revert if unequal number of URIs and supplies are provided", async () => {
      await expect(
        accessNft
          .connect(creator)
          .createAccessPack(
            pack.address,
            rewardURIs.slice(1),
            accessURIs,
            rewardSupplies,
            packURI,
            openStartAndEnd,
            openStartAndEnd,
            rewardsPerOpen,
          ),
      ).to.be.revertedWith("AccessNFT: Must specify equal number of config values.");

      await expect(
        accessNft
          .connect(creator)
          .createAccessPack(
            pack.address,
            rewardURIs,
            accessURIs.slice(1),
            rewardSupplies,
            packURI,
            openStartAndEnd,
            openStartAndEnd,
            rewardsPerOpen,
          ),
      ).to.be.revertedWith("AccessNFT: Must specify equal number of config values.");

      await expect(
        accessNft
          .connect(creator)
          .createAccessPack(
            pack.address,
            rewardURIs,
            accessURIs,
            rewardSupplies.slice(1),
            packURI,
            openStartAndEnd,
            openStartAndEnd,
            rewardsPerOpen,
          ),
      ).to.be.revertedWith("AccessNFT: Must specify equal number of config values.");
    });

    it("Should revert if no NFTs are to be created", async () => {
      await expect(
        accessNft
          .connect(creator)
          .createAccessPack(pack.address, [], [], [], packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen),
      ).to.be.revertedWith("AccessNFT: Must create at least one NFT.");
    });

    it("Should revert if caller does not have MINTER_ROLE", async () => {
      await expect(
        accessNft
          .connect(relayer)
          .createAccessPack(
            pack.address,
            rewardURIs,
            accessURIs,
            rewardSupplies,
            packURI,
            openStartAndEnd,
            openStartAndEnd,
            rewardsPerOpen,
          ),
      ).to.be.reverted;
    });

    it("Should revert if total supply of NFTs is not divisible by the number of NFTs to distribute on pack opening.", async () => {
      const invalidRewardsPerOpen = rewardSupplies.reduce((a, b) => a + b) - 1;
      await expect(
        accessNft
          .connect(creator)
          .createAccessPack(
            pack.address,
            rewardURIs,
            accessURIs,
            rewardSupplies,
            packURI,
            openStartAndEnd,
            openStartAndEnd,
            invalidRewardsPerOpen,
          ),
      ).to.be.revertedWith("Pack: invalid number of rewards per open.");
    });
  });

  describe("Events", function () {
    it("Should emit AccessNFTsCreated", async () => {
      const eventPromise = new Promise(async (resolve, reject) => {
        const nextAccessNftId: number = parseInt((await accessNft.nextTokenId()).toString());

        accessNft.on("AccessNFTsCreated", (_creator, _nftIds, _nftURIs, _accessNftIds, _accessURIs, _nftSupplies) => {
          expect(_creator).to.equal(creator.address);

          for (let i = 0; i < rewardURIs.length; i++) {
            expect(rewardURIs[i]).to.equal(_nftURIs[i]);
            expect(accessURIs[i]).to.equal(_accessURIs[i]);
            expect(rewardSupplies[i]).to.equal(_nftSupplies[i]);
          }

          expect(_nftIds.length).to.equal(_accessNftIds.length);

          for (let val of [...Array(nextAccessNftId).keys()]) {
            if (val % 2 == 0) {
              expect(_accessNftIds.includes(val));
            } else {
              expect(_nftIds.includes(val));
            }
          }

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: AccessNFTsCreated"));
        }, 10000);
      });

      await accessNft
        .connect(creator)
        .createAccessPack(
          pack.address,
          rewardURIs,
          accessURIs,
          rewardSupplies,
          packURI,
          openStartAndEnd,
          openStartAndEnd,
          rewardsPerOpen,
        );

      await eventPromise;
    });

    it("Should emit PackCreated", async () => {
      const packId = await pack.nextTokenId();

      const eventPromise = new Promise((resolve, reject) => {
        pack.on("PackCreated", (_packId, _rewardContract, _creator, _packState, _rewards) => {
          expect(_packId).to.equal(packId);
          expect(_rewardContract).to.equal(accessNft.address);
          expect(_creator).to.equal(creator.address);

          expect(_packState.uri).to.equal(packURI);
          expect(_packState.creator).to.equal(creator.address);
          expect(_packState.currentSupply).to.equal(rewardSupplies.reduce((a, b) => a + b) / rewardsPerOpen);

          expect(_rewards.source).to.equal(accessNft.address);
          expect(_rewards.rewardsPerOpen).to.equal(rewardsPerOpen);

          expect(rewardURIs.length).to.equal(_rewards.tokenIds.length);
          expect(rewardURIs.length).to.equal(_rewards.amountsPacked.length);

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: PackCreated"));
        }, 10000);
      });

      await accessNft
        .connect(creator)
        .createAccessPack(
          pack.address,
          rewardURIs,
          accessURIs,
          rewardSupplies,
          packURI,
          openStartAndEnd,
          openStartAndEnd,
          rewardsPerOpen,
        );

      await eventPromise;
    });
  });

  describe("Balances", async () => {
    let packId: number;
    let rewardIds: number[];
    let accessIds: number[];

    beforeEach(async () => {
      packId = parseInt((await pack.nextTokenId()).toString());

      await accessNft
        .connect(creator)
        .createAccessPack(
          pack.address,
          rewardURIs,
          accessURIs,
          rewardSupplies,
          packURI,
          openStartAndEnd,
          openStartAndEnd,
          rewardsPerOpen,
        );

      const nextAccessNftId: number = parseInt((await accessNft.nextTokenId()).toString());
      const expectedRewardIds: number[] = [];
      const expectedAccessIds: number[] = [];
      for (let val of [...Array(nextAccessNftId).keys()]) {
        if (val % 2 == 0) {
          expectedAccessIds.push(val);
        } else {
          expectedRewardIds.push(val);
        }
      }

      rewardIds = expectedRewardIds;
      accessIds = expectedAccessIds;
    });

    it("Should mint all access NFTs to the AccessNFT contract", async () => {
      expect(accessIds.length).to.equal(rewardSupplies.length);

      for (let i = 0; i < rewardSupplies.length; i++) {
        expect(await accessNft.balanceOf(accessNft.address, accessIds[i])).to.equal(rewardSupplies[i]);
      }
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
    let packId: number;
    let nextAccessNftId: number;
    let rewardIds: number[];
    let accessIds: number[];

    beforeEach(async () => {
      packId = parseInt((await pack.nextTokenId()).toString());

      await accessNft
        .connect(creator)
        .createAccessPack(
          pack.address,
          rewardURIs,
          accessURIs,
          rewardSupplies,
          packURI,
          openStartAndEnd,
          openStartAndEnd,
          rewardsPerOpen,
        );

      nextAccessNftId = parseInt((await accessNft.nextTokenId()).toString());
      const expectedRewardIds: number[] = [];
      const expectedAccessIds: number[] = [];
      for (let val of [...Array(nextAccessNftId).keys()]) {
        if (val % 2 == 0) {
          expectedAccessIds.push(val);
        } else {
          expectedRewardIds.push(val);
        }
      }

      rewardIds = expectedRewardIds;
      accessIds = expectedAccessIds;
    });

    it("Should increment the contract level tokenId by twice the number of URIs", async () => {
      expect(nextAccessNftId).to.equal(rewardURIs.length * 2);
    });

    it("Should store the NFT info for all NFTs created: redeemed and unredeemed", async () => {
      expect(rewardIds.length).to.equal(accessIds.length);

      for (let i = 0; i < rewardIds.length; i++) {
        const rewardInfo = await accessNft.nftInfo(rewardIds[i]);
        expect(rewardInfo.uri).to.equal(rewardURIs[i]);
        expect(rewardInfo.creator).to.equal(creator.address);
        expect(rewardInfo.supply).to.equal(rewardSupplies[i]);
        expect(rewardInfo.isAccess).to.equal(false);
        expect(rewardInfo.underlyingType).to.equal(0);

        const acessNftInfo = await accessNft.nftInfo(accessIds[i]);
        expect(acessNftInfo.uri).to.equal(accessURIs[i]);
        expect(acessNftInfo.creator).to.equal(creator.address);
        expect(acessNftInfo.supply).to.equal(rewardSupplies[i]);
        expect(acessNftInfo.isAccess).to.equal(true);
        expect(acessNftInfo.underlyingType).to.equal(0);
      }
    });

    it("Should store the state of the packs just created", async () => {
      const packState = await pack.getPackWithRewards(packId);

      expect(packState.pack.uri).to.equal(packURI);
      expect(packState.pack.creator).to.equal(creator.address);
      expect(packState.pack.currentSupply).to.equal(rewardSupplies.reduce((a, b) => a + b) / rewardsPerOpen);

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
