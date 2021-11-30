import { ethers } from "hardhat";
import { expect } from "chai";

// Contract Types
import { Forwarder } from "../../../typechain/Forwarder";
import { AccessNFT } from "../../../typechain/AccessNFT";
import { Coin } from "../../../typechain/Coin";
import { ProtocolControl } from "../../../typechain/ProtocolControl";
import { MarketWithAuction, ListingParametersStruct, ListingStruct } from "../../../typechain/MarketWithAuction";

// Types
import { BigNumber, BigNumberish } from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";
import { getURIs, getAmounts, getBoundedEtherAmount, getAmountBounded } from "../../../utils/tests/params";
import { sendGaslessTx } from "../../../utils/tests/gasless";

describe("Accept offer: direct listing", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let buyer: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let marketv2: MarketWithAuction;
  let protocolControl: ProtocolControl;
  let accessNft: AccessNFT;
  let coin: Coin;
  let forwarder: Forwarder;

  // Reward parameters
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getAmounts(rewardURIs.length);
  const emptyData: BytesLike = ethers.utils.toUtf8Bytes("");

  // Token IDs
  let rewardId: number = 1;

  // Market params
  enum ListingType { Direct = 0, Auction = 1 }
  const buyoutPricePerToken: BigNumber = ethers.utils.parseEther("2");
  const totalQuantityOwned: BigNumberish = rewardSupplies[0]
  const quantityToList = totalQuantityOwned;
  const secondsUntilStartTime: number = 0;
  const secondsUntilEndTime: number = 0;

  let listingParams: ListingParametersStruct;
  let listingId: BigNumberish;

  const quantityWanted: BigNumberish = 1;
  const offerAmount = ethers.utils.parseEther("1");

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, creator, buyer, relayer] = signers;
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    marketv2 = contracts.marketv2;
    accessNft = contracts.accessNft;
    coin = contracts.coin;
    forwarder = contracts.forwarder;
    protocolControl = contracts.protocolControl;

    // Grant minter role to creator
    const MINTER_ROLE = await accessNft.MINTER_ROLE();
    await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

    // Create access tokens
    await sendGaslessTx(creator, forwarder, relayer, {
      from: creator.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("createAccessTokens", [
        creator.address,
        rewardURIs,
        accessURIs,
        rewardSupplies,
        emptyData,
      ]),
    });

    // Approve Market to transfer tokens
    await accessNft.connect(creator).setApprovalForAll(marketv2.address, true);

    // List tokens for sale: direct listing
    listingParams = {
      assetContract: accessNft.address,
      tokenId: rewardId,
      
      secondsUntilStartTime: secondsUntilStartTime,
      secondsUntilEndTime: secondsUntilEndTime,

      quantityToList: quantityToList,
      currencyToAccept: coin.address,

      reservePricePerToken: 0,
      buyoutPricePerToken: buyoutPricePerToken,

      listingType: ListingType.Direct
    }

    listingId = await marketv2.totalListings();
    await marketv2.connect(creator).createListing(listingParams);

    // Mint currency to buyer
    await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

    // Approve Market to transfer currency
    await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));

    await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
  });

  describe("Revert cases", function() {
    
    it("Should revert if listing is an auction", async () => {
      const newListingId = await marketv2.totalListings();
      const newListingParams = {...listingParams, listingType: ListingType.Auction};

      await marketv2.connect(creator).createListing(newListingParams);
      await marketv2.connect(buyer).offer(newListingId, quantityWanted, offerAmount)

      await expect(
        marketv2.connect(creator).acceptOffer(newListingId, buyer.address)
      ).to.be.revertedWith("Market: must own and approve to transfer tokens.");
    })

    it("Should revert if lister does not own tokens listed", async () => {
      // Transfer away tokens
      await accessNft.connect(creator).safeTransferFrom(
        creator.address, relayer.address, rewardId, totalQuantityOwned, ethers.utils.toUtf8Bytes("")
      );

      await expect(
        marketv2.connect(creator).acceptOffer(listingId, buyer.address)
      ).to.be.revertedWith("Market: must own and approve to transfer tokens.");
    })

    it("Should revert if lister has not approved market to transfer tokens", async () => {
      // Remove transfer approval
      await accessNft.connect(creator).setApprovalForAll(marketv2.address, false);

      await expect(
        marketv2.connect(creator).acceptOffer(listingId, buyer.address)
      ).to.be.revertedWith("Market: must own and approve to transfer tokens.");
    })

    it("Should revert if offeror's currency balance is less than offer amount", async () => {
      // Transfer away currency
      const buyerBal: BigNumber = await coin.balanceOf(buyer.address);
      await coin.connect(buyer).transfer(relayer.address, buyerBal);

      await expect(
        marketv2.connect(creator).acceptOffer(listingId, buyer.address)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance")
    })
  })

  describe("Events", function() {
    it("Should emit NewDirectSale with relevan sale info", async () => {

      const eventPromise = new Promise((resolve, reject) => {
        marketv2.on("NewDirectSale", (
          _assetContract,
          _seller,
          _listingId,
          _buyer,
          _quantityBought,
          _listing
        ) => {
          expect(_assetContract).to.equal(accessNft.address)
          expect(_seller).to.equal(creator.address)
          expect(_listingId).to.equal(listingId)
          expect(_buyer).to.equal(buyer.address)
          expect(_quantityBought).to.equal(quantityWanted)
          expect(_listing.quantity).to.equal(quantityToList - quantityWanted);

          resolve(null);
        })

        setTimeout(() => {
          reject(new Error("Timeout: NewDirectSale"));
        }, 10000)
      })

      await marketv2.connect(creator).acceptOffer(listingId, buyer.address)

      await eventPromise.catch(e => console.error(e));
    })
  })

  describe("Balances", function() {
    it("Should payout the lister with the offer amount", async () => {
      const creatorBalBefore: BigNumber = await coin.balanceOf(creator.address)
      const buyerBalBefore: BigNumber = await coin.balanceOf(buyer.address);

      await marketv2.connect(creator).acceptOffer(listingId, buyer.address)

      const creatorBalAfter: BigNumber = await coin.balanceOf(creator.address)
      const buyerBalAfter: BigNumber = await coin.balanceOf(buyer.address);

      expect(creatorBalAfter).to.equal(creatorBalBefore.add(offerAmount))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(offerAmount))
    })

    it("Should transfer the given amount listed tokens to offeror", async () => {
      const creatorBalBefore: BigNumber = await accessNft.balanceOf(creator.address, rewardId)
      const buyerBalBefore: BigNumber = await accessNft.balanceOf(buyer.address, rewardId);

      await marketv2.connect(creator).acceptOffer(listingId, buyer.address)

      const creatorBalAfter: BigNumber = await accessNft.balanceOf(creator.address, rewardId)
      const buyerBalAfter: BigNumber = await accessNft.balanceOf(buyer.address, rewardId);

      expect(creatorBalAfter).to.equal(creatorBalBefore.sub(quantityWanted))
      expect(buyerBalAfter).to.equal(buyerBalBefore.add(quantityWanted))
    })
  })

  describe("Contract state", function() {

    it("Should uopdate the listing quantity", async () => {
      const listingQuantityBefore: BigNumber = (await marketv2.listings(listingId)).quantity;
      await marketv2.connect(creator).acceptOffer(listingId, buyer.address)
      const listingQuantityAfter: BigNumber = (await marketv2.listings(listingId)).quantity;

      expect(listingQuantityAfter).to.equal(listingQuantityBefore.sub(quantityWanted));
    });

    it("Should reset the offer made", async () => {
      await marketv2.connect(creator).acceptOffer(listingId, buyer.address)

      const offer = await marketv2.offers(listingId, buyer.address);

      expect(offer.offerAmount).to.equal(0);
      expect(offer.quantityWanted).to.equal(0);
    })
  })
});
