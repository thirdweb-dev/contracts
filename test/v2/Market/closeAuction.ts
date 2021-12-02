import { ethers } from "hardhat";
import { expect } from "chai";

// Contract Types
import { Forwarder } from "../../../typechain/Forwarder";
import { AccessNFT } from "../../../typechain/AccessNFT";
import { Coin } from "../../../typechain/Coin";
import { MarketWithAuction, ListingParametersStruct, ListingStruct } from "../../../typechain/MarketWithAuction";

// Types
import { BigNumberish, BigNumber, Signer } from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";
import { getURIs, getAmounts, getBoundedEtherAmount, getAmountBounded } from "../../../utils/tests/params";
import { sendGaslessTx } from "../../../utils/tests/gasless";

describe("Close / Cancel auction", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let buyer: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let marketv2: MarketWithAuction;
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
  enum TokenType { ERC1155, ERC721 }
  enum ListingType { Direct = 0, Auction = 1 }
  const buyoutPricePerToken: BigNumber = ethers.utils.parseEther("2");
  const reservePricePerToken: BigNumberish = ethers.utils.parseEther("1");
  const totalQuantityOwned: BigNumberish = rewardSupplies[0]
  const quantityToList = totalQuantityOwned;
  const secondsUntilStartTime: number = 100;
  const secondsUntilEndTime: number = 200;

  let listingParams: ListingParametersStruct;
  let listingId: BigNumberish;

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

    listingParams = {
      assetContract: accessNft.address,
      tokenId: rewardId,
      
      startTime: BigNumber.from(
        (await ethers.provider.getBlock("latest")).timestamp
      ).add(100),
      secondsUntilEndTime: BigNumber.from(1000),

      quantityToList: quantityToList,
      currencyToAccept: coin.address,

      reservePricePerToken: reservePricePerToken,
      buyoutPricePerToken: buyoutPricePerToken,

      listingType: ListingType.Auction
    }

    listingId = await marketv2.totalListings();
    await marketv2.connect(creator).createListing(listingParams);

    // Mint currency to buyer
    await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

    // Approve Market to transfer currency
    await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
  });

  describe("Cancel auction", function() {
    
    describe("Revert cases", function() {
      it("Should revert if caller is not auction creator.", async () => {
        await expect(
          marketv2.connect(buyer).closeAuction(listingId)
        ).to.be.revertedWith("Market: caller is not the listing creator.")
      })
    })

    describe("Events", function() {
      it("Should emit AuctionCanceled with relevant info", async () => {

        const timeStampOfEnd = (await ethers.provider.getBlock("latest")).timestamp + 1;

        await expect(
          marketv2.connect(creator).closeAuction(listingId)
        ).to.emit(marketv2, "AuctionCanceled")
        .withArgs(
          ...Object.values({
            listingId: listingId,
            auctionCreator: creator.address,
            listing: Object.values({
              listingId: listingId,
              tokenOwner: creator.address,
              assetContract: listingParams.assetContract,
              tokenId: listingParams.tokenId,
              startTime: listingParams.startTime,
              endTime: timeStampOfEnd,
              quantity: 0,
              currency: listingParams.currencyToAccept,
              reservePricePerToken: listingParams.reservePricePerToken,
              buyoutPricePerToken: listingParams.buyoutPricePerToken,
              tokenType: TokenType.ERC1155,
              listingType: ListingType.Auction
            })
          })
        )
      })
    })

    describe("Balances", function() {

      it("Should transfer back tokens to auction creator", async () => {
        const creatorBalBefore: BigNumber = await accessNft.balanceOf(creator.address, rewardId)
        const marketBalBefore: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId)
        
        await marketv2.connect(creator).closeAuction(listingId)

        const creatorBalAfter: BigNumber = await accessNft.balanceOf(creator.address, rewardId)
        const marketBalAfter: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId)

        expect(creatorBalAfter).to.equal(creatorBalBefore.add(quantityToList))
        expect(marketBalAfter).to.equal(marketBalBefore.sub(quantityToList))
      })
    })

    describe("Contract state", function() {
      it("Should reset listing end time and quantity", async () => {
        await marketv2.connect(creator).closeAuction(listingId)

        const listing = await marketv2.listings(listingId);

        expect(listing.quantity).to.equal(0)
        const timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
        expect(listing.endTime).to.equal(timeStamp);
      })
    })
  })

  describe("Regular auction closing", function() {

    let quantityWanted: BigNumberish;
    let offerPricePerToken: BigNumber;
    let currencyForOffer: string;
    let totalOfferAmount: BigNumber;

    beforeEach(async () => {

      quantityWanted = 1;
      offerPricePerToken = reservePricePerToken;
      currencyForOffer = listingParams.currencyToAccept;
      totalOfferAmount = offerPricePerToken.mul(quantityToList);

      // Time travel
      const listingStart: string = (await marketv2.listings(listingId)).startTime.toString();
      await ethers.provider.send("evm_mine", [parseInt(listingStart)]);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
    })

    describe("Revert cases", function() {
      
      it("Should revert if caller is not auction creator or bidder.", async () => {
        await expect(
          marketv2.connect(relayer).closeAuction(listingId)
        ).to.be.revertedWith("Market: must be bidder or auction creator.")
      })

      it("Should revert if listing is not an auction.", async () => {
        const newListingId = await marketv2.totalListings();
        const newListingParams = {...listingParams, tokenId: 3, quantityToList: 1, secondsUntilStartTime: 0, listingType: ListingType.Direct};

        await marketv2.connect(creator).createListing(newListingParams);

        await expect(
          marketv2.connect(creator).closeAuction(newListingId)
        ).to.be.revertedWith("Market: listing is not an auction.");
      })

      it("Should revert if the auction duration is not over.", async () => {
        await expect(
          marketv2.connect(creator).closeAuction(listingId)
        ).to.be.revertedWith("Market: can only close auction after it has ended.")
      })
    })

    describe("Events", function() {

      beforeEach(async () => {

        // Time travel to auction end
        const endTime: BigNumber = (await marketv2.listings(listingId)).endTime;
        while(true) {
          await ethers.provider.send("evm_mine", []);

          const timeStamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
          if(endTime.lt(timeStamp)) {
            break;
          }
        }
      })

      it("Should emit AuctionClosed with relevant closing info: closed by lister", async () => {

        const timeStampOfEnd = (await ethers.provider.getBlock("latest")).timestamp + 1;
        const listing: ListingStruct = await marketv2.listings(listingId);

        await expect(
          marketv2.connect(creator).closeAuction(listingId)
        ).to.emit(marketv2, "AuctionClosed")
        .withArgs(
          ...Object.values({
            listingId: listingId,
            closer: creator.address,
            auctionCreator: creator.address,
            winningBidder: buyer.address,
            winningBid: Object.values({
              listingId: listingId,
              offeror: buyer.address,
              quantityWanted: listingParams.quantityToList,
              currency: currencyForOffer,
              pricePerToken: 0
            }),
            listing: Object.values({
              listingId: listingId,
              tokenOwner: creator.address,
              assetContract: listingParams.assetContract,
              tokenId: listingParams.tokenId,
              startTime: listing.startTime,
              endTime: timeStampOfEnd,
              quantity: 0,
              currency: listingParams.currencyToAccept,
              reservePricePerToken: listingParams.reservePricePerToken,
              buyoutPricePerToken: listingParams.buyoutPricePerToken,
              tokenType: TokenType.ERC1155,
              listingType: ListingType.Auction
            })
          })
        )
      })

      it("Should emit AuctionClosed with relevant closing info: closed by bidder", async () => {

        const listing: ListingStruct = await marketv2.listings(listingId);

        await expect(
          marketv2.connect(buyer).closeAuction(listingId)
        ).to.emit(marketv2, "AuctionClosed")
        .withArgs(
          ...Object.values({
            listingId: listingId,
            closer: buyer.address,
            auctionCreator: creator.address,
            winningBidder: buyer.address,
            winningBid: Object.values({
              listingId: listingId,
              offeror: buyer.address,
              quantityWanted: 0,
              currency: currencyForOffer,
              pricePerToken: offerPricePerToken
            }),
            listing: Object.values({
              listingId: listingId,
              tokenOwner: creator.address,
              assetContract: listingParams.assetContract,
              tokenId: listingParams.tokenId,
              startTime: listing.startTime,
              endTime: listing.endTime,
              quantity: listing.quantity,
              currency: listingParams.currencyToAccept,
              reservePricePerToken: listingParams.reservePricePerToken,
              buyoutPricePerToken: listingParams.buyoutPricePerToken,
              tokenType: TokenType.ERC1155,
              listingType: ListingType.Auction
            })
          })
        )
      })
    })

    describe("Balances", function() {

      beforeEach(async () => {

        // Time travel to auction end
        const endTime: BigNumber = (await marketv2.listings(listingId)).endTime;
        while(true) {
          await ethers.provider.send("evm_mine", []);

          const timeStamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
          if(endTime.lt(timeStamp)) {
            break;
          }
        }
      })
      
      it("Should payout bid to lister when called by lister", async () => {
        
        const creatorBalBefore: BigNumber = await coin.balanceOf(creator.address)
        const marketBalBefore: BigNumber = await coin.balanceOf(marketv2.address);

        await marketv2.connect(creator).closeAuction(listingId)

        const creatorBalAfter: BigNumber = await coin.balanceOf(creator.address)
        const marketBalAfter: BigNumber = await coin.balanceOf(marketv2.address);

        expect(creatorBalAfter).to.equal(creatorBalBefore.add(totalOfferAmount))
        expect(marketBalAfter).to.equal(marketBalBefore.sub(totalOfferAmount))
      })

      it("Should transfer auctioned tokens to bidder when called by bidder", async () => {
        const marketBalBefore: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId)
        const buyerBalBefore: BigNumber = await accessNft.balanceOf(buyer.address, rewardId);

        await marketv2.connect(buyer).closeAuction(listingId)

        const marketBalAfter: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId)
        const buyerBalAfter: BigNumber = await accessNft.balanceOf(buyer.address, rewardId);

        expect(marketBalAfter).to.equal(marketBalBefore.sub(quantityToList))
        expect(buyerBalAfter).to.equal(buyerBalBefore.add(quantityToList))
      })

      it("Should not affect any currency balances on repeat calls by bidder of lister", async () => {
        await marketv2.connect(creator).closeAuction(listingId)
        await marketv2.connect(buyer).closeAuction(listingId)
        
        const creatorBalBefore: BigNumber = await coin.balanceOf(creator.address)
        const marketBalBefore: BigNumber = await coin.balanceOf(marketv2.address);

        await marketv2.connect(creator).closeAuction(listingId)

        const creatorBalAfter: BigNumber = await coin.balanceOf(creator.address)
        const marketBalAfter: BigNumber = await coin.balanceOf(marketv2.address);

        expect(creatorBalAfter).to.equal(creatorBalBefore)
        expect(marketBalBefore).to.equal(marketBalAfter)
      })

      it("Should not affect any token balances on repeat calls by bidder of lister", async () => {
        await marketv2.connect(creator).closeAuction(listingId)
        await marketv2.connect(buyer).closeAuction(listingId)
        
        const marketBalBefore: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId)
        const buyerBalBefore: BigNumber = await accessNft.balanceOf(buyer.address, rewardId);

        await marketv2.connect(buyer).closeAuction(listingId)

        const marketBalAfter: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId)
        const buyerBalAfter: BigNumber = await accessNft.balanceOf(buyer.address, rewardId);

        expect(marketBalAfter).to.equal(marketBalBefore)
        expect(buyerBalAfter).to.equal(buyerBalBefore)
      })
    })

    describe("Contract state", function() {

      beforeEach(async () => {

        // Time travel to auction end
        const endTime: BigNumber = (await marketv2.listings(listingId)).endTime;
        while(true) {
          await ethers.provider.send("evm_mine", []);

          const timeStamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
          if(endTime.lt(timeStamp)) {
            break;
          }
        }
      })

      it("Should reset listing quantity, end time, and offer's offer amount when called by lister", async () => {
        await marketv2.connect(creator).closeAuction(listingId)

        const listing = await marketv2.listings(listingId)
        expect(listing.quantity).to.equal(0)
        expect(listing.endTime).to.equal(
          (await ethers.provider.getBlock("latest")).timestamp
        )

        const offer = await marketv2.winningBid(listingId)
        expect(offer.pricePerToken).to.equal(0);
      })

      it("Should reset the bid's quantity when called by bidder", async () => {
        await marketv2.connect(buyer).closeAuction(listingId)

        const offer = await marketv2.winningBid(listingId)
        expect(offer.quantityWanted).to.equal(0);
      })
    })
  })
});