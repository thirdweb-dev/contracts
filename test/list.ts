// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFTPL } from "../typechain/AccessNFTPL";
import { PackPL } from "../typechain/PackPL";
import { Market } from "../typechain/Market";
import { Coin } from "../typechain/Coin";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../utils/tests/getContracts";
import {
  getURIs,
  getSupplies,
  openStartAndEnd,
  rewardsPerOpen,
  pricePerToken,
  amountToList,
  maxTokensPerBuyer,
} from "../utils/tests/params";
import { BigNumber } from "ethers";

describe("List token for sale", function () {
  // Signers
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: PackPL;
  let market: Market;
  let accessNft: AccessNFTPL;
  let coin: Coin;

  // Reward parameters
  const [packURI]: string[] = getURIs(1);
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getSupplies(rewardURIs.length);

  // Expected results
  let packId: BigNumber;

  // Market params
  const price: BigNumber = pricePerToken();
  const amountOfTokenToList = amountToList(rewardSupplies.reduce((a, b) => a + b));
  const tokensPerBuyer = maxTokensPerBuyer(parseInt(amountOfTokenToList.toString()));

  beforeEach(async () => {
    // Get signers
    const networkName: string = "mumbai";
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [creator, relayer] = signers;

    // Get contracts
    const contracts: Contracts = await getContracts(creator, networkName);
    pack = contracts.pack;
    market = contracts.market;
    accessNft = contracts.accessNft;
    coin = contracts.coin;

    // Get expected IDs
    packId = await pack.nextTokenId();
    let rewardIds: number[];
    let accessIds: number[];

    // Create access packs
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

    // Get NFT IDs
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

  describe("Revert", async () => {
    it("Should revert if no amount of tokens is listed", async () => {
      const invalidQuantity: number = 0;

      await expect(
        market
          .connect(creator)
          .list(
            pack.address,
            packId,
            coin.address,
            price,
            invalidQuantity,
            tokensPerBuyer,
            openStartAndEnd,
            openStartAndEnd,
          ),
      ).to.be.revertedWith("Market: must list at least one token.");
    });

    it("Should revert if Market is not approved to transfer tokens", async () => {
      await expect(
        market
          .connect(creator)
          .list(
            pack.address,
            packId,
            coin.address,
            price,
            amountOfTokenToList,
            tokensPerBuyer,
            openStartAndEnd,
            openStartAndEnd,
          ),
      ).to.be.reverted;
    });
  });

  describe("Events", function () {
    beforeEach(async () => {
      // Approve Market to transfer tokens
      await pack.connect(creator).setApprovalForAll(market.address, true);
    });

    it("Should emit NewListing", async () => {
      const listingId: BigNumber = await market.totalListings();

      const eventPromise = new Promise((resolve, reject) => {
        market.on("NewListing", (_assetContract, _seller, _listingId, _listing) => {
          expect(_assetContract).to.equal(pack.address);
          expect(_seller).to.equal(creator.address);
          expect(_listingId).to.equal(listingId);

          expect(_listing.listingId).to.equal(listingId);
          expect(_listing.seller).to.equal(creator.address);
          expect(_listing.assetContract).to.equal(pack.address);
          expect(_listing.tokenId).to.equal(packId);
          expect(_listing.quantity).to.equal(amountOfTokenToList);
          expect(_listing.currency).to.equal(coin.address);
          expect(_listing.pricePerToken).to.equal(price);
          expect(_listing.tokenType).to.equal(0); // 0 == ERC1155 i.e. pack / NFTCollection / AccessNFT

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout: NewListing"));
        }, 10000);
      });

      await market
        .connect(creator)
        .list(
          pack.address,
          packId,
          coin.address,
          price,
          amountOfTokenToList,
          tokensPerBuyer,
          openStartAndEnd,
          openStartAndEnd,
        );

      await eventPromise;
    });
  });

  describe("Balances", function () {
    beforeEach(async () => {
      // Approve Market to transfer tokens
      await pack.connect(creator).setApprovalForAll(market.address, true);

      // List tokens
      await market
        .connect(creator)
        .list(
          pack.address,
          packId,
          coin.address,
          price,
          amountOfTokenToList,
          tokensPerBuyer,
          openStartAndEnd,
          openStartAndEnd,
        );
    });

    it("Should transfer all tokens from seller to Market", async () => {
      expect(await pack.balanceOf(creator.address, packId)).to.equal(
        BigNumber.from(rewardSupplies.reduce((a, b) => a + b)).sub(amountOfTokenToList),
      );

      expect(await pack.balanceOf(market.address, packId)).to.equal(amountOfTokenToList);
    });
  });

  describe("Contract state", function () {
    let listingId: BigNumber;

    beforeEach(async () => {
      // Approve Market to transfer tokens
      await pack.connect(creator).setApprovalForAll(market.address, true);

      // Get listing Id
      listingId = await market.totalListings();

      // List tokens
      await market
        .connect(creator)
        .list(
          pack.address,
          packId,
          coin.address,
          price,
          amountOfTokenToList,
          tokensPerBuyer,
          openStartAndEnd,
          openStartAndEnd,
        );
    });

    it("Should increment the number of total listings on the market", async () => {
      expect(await market.totalListings()).to.equal(listingId.add(1));
    });

    it("Should store the state of the lsiting created", async () => {
      const listing = await market.listings(listingId);

      expect(listing.listingId).to.equal(listingId);
      expect(listing.seller).to.equal(creator.address);
      expect(listing.assetContract).to.equal(pack.address);
      expect(listing.tokenId).to.equal(packId);
      expect(listing.quantity).to.equal(amountOfTokenToList);
      expect(listing.currency).to.equal(coin.address);
      expect(listing.pricePerToken).to.equal(price);
      expect(listing.tokenType).to.equal(0); // 0 == ERC1155 i.e. pack / NFTCollection / AccessNFT
    });
  });
});
