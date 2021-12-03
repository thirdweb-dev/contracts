import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155 } from "../../../../typechain/MockERC1155";
import { Coin } from "../../../../typechain/Coin";
import { Marketplace, ListingParametersStruct, ListingStruct } from "../../../../typechain/Marketplace";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";

use(solidity);

describe("Close / Cancel auction: ERC20 token", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let lister: SignerWithAddress;
  let buyer: SignerWithAddress;
  let dummy: SignerWithAddress;

  // Contracts
  let marketv2: Marketplace;
  let mockNft: MockERC1155;
  let erc20Token: Coin;

  // MockERC1155: `mint` parameters
  const nftTokenId: BigNumber = BigNumber.from(1);
  const nftTokenSupply: BigNumber = BigNumber.from(
    Math.floor((1 + Math.random())) * 5
  );

  // Market: `createListing` params
  enum ListingType { Direct, Auction }
  enum TokenType { ERC1155, ERC721 }
  let listingId: BigNumber;
  let listingParams: ListingParametersStruct;

  // Market: `offer` params
  let quantityWanted: BigNumber;
  let offerPricePerToken: BigNumber;
  let currencyForOffer: string;
  let totalOfferAmount: BigNumber;

  // Semantic helpers
  const mintNftToLister = async () => await mockNft.connect(protocolAdmin).mint(
    lister.address,
    nftTokenId,
    nftTokenSupply,
    ethers.utils.toUtf8Bytes("")
  );

  const mintERC20To = async (to: SignerWithAddress, amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(protocolAdmin).mint(to.address, amount);

    // Approve Market to transfer currency
    await erc20Token.connect(to).approve(marketv2.address, amount);
  }

  const approveMarketToTransferTokens = async (toApprove: boolean) => await mockNft.connect(lister).setApprovalForAll(marketv2.address, toApprove);
  
  const timeTravelToListingWindow = async (listingId: BigNumber) => {
    // Time travel
    const listingStart: string = (await marketv2.listings(listingId)).startTime.toString();
    await ethers.provider.send("evm_mine", [parseInt(listingStart)]);
  }

  const timeTravelToAfterListingWindow = async (listingId: BigNumber) => {
    // Time travel
    const listingEnd: string = (await marketv2.listings(listingId)).endTime.toString();
    await ethers.provider.send("evm_mine", [parseInt(listingEnd)]);
  }

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, lister, buyer, dummy] = signers;
  });

  beforeEach(async () => {
    // Get contracts
    mockNft = await ethers.getContractFactory("MockERC1155").then(f => f.connect(protocolAdmin).deploy());
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    marketv2 = contracts.marketv2;
    erc20Token = contracts.coin;

    // Setup: mint NFT to `lister` for `lister` to list these NFTs for sale.
    await mintNftToLister();

    // Setup: `lister` approves Market to transfer tokens.
    await approveMarketToTransferTokens(true);

    // Setup: get expected listingId
    listingId = await marketv2.totalListings();

    // Setup: set default `createListing` paramters.
    listingParams = {
      assetContract: mockNft.address,
      tokenId: nftTokenId,
      
      startTime: BigNumber.from(
        (await ethers.provider.getBlock("latest")).timestamp
      ).add(100),
      secondsUntilEndTime: BigNumber.from(1000),

      quantityToList: nftTokenSupply,
      currencyToAccept: erc20Token.address,

      reservePricePerToken: ethers.utils.parseEther("0.01"),
      buyoutPricePerToken: ethers.utils.parseEther("0.02"),

      listingType: ListingType.Auction
    }

    // Setup: `lister` lists nft for sale in a direct listing.
    await marketv2.connect(lister).createListing(listingParams)

    // Setup: set default `offer` parameters.
    quantityWanted = BigNumber.from(1);
    offerPricePerToken = listingParams.reservePricePerToken as BigNumber;
    currencyForOffer = listingParams.currencyToAccept;
    totalOfferAmount = offerPricePerToken.mul(listingParams.quantityToList);

    // Setup: mint some curreny to buyer so they can fulfill the offer made.
    await mintERC20To(
      buyer,
      (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
    )
  });

  describe("Cancel auction", function() {
    
    describe("Revert cases", function() {
      it("Should revert if caller is not auction lister.", async () => {
        await expect(
          marketv2.connect(buyer).closeAuction(listingId)
        ).to.be.revertedWith("Market: caller is not the listing creator.")
      })
    })

    describe("Events", function() {
      it("Should emit AuctionCanceled with relevant info", async () => {

        const timeStampOfEnd = (await ethers.provider.getBlock("latest")).timestamp + 1;

        await expect(
          marketv2.connect(lister).closeAuction(listingId)
        ).to.emit(marketv2, "AuctionCanceled")
        .withArgs(
          ...Object.values({
            listingId: listingId,
            auctionlister: lister.address,
            listing: Object.values({
              listingId: listingId,
              tokenOwner: lister.address,
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

      it("Should transfer back tokens to auction lister", async () => {
        const listerBalBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId)
        const marketBalBefore: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId)
        
        await marketv2.connect(lister).closeAuction(listingId)

        const listerBalAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId)
        const marketBalAfter: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId)

        expect(listerBalAfter).to.equal(listerBalBefore.add(listingParams.quantityToList))
        expect(marketBalAfter).to.equal(marketBalBefore.sub(listingParams.quantityToList))
      })
    })

    describe("Contract state", function() {
      it("Should reset listing end time and quantity", async () => {
        await marketv2.connect(lister).closeAuction(listingId)

        const listing = await marketv2.listings(listingId);

        expect(listing.quantity).to.equal(0)
        const timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
        expect(listing.endTime).to.equal(timeStamp);
      })
    })
  })

  describe("Regular auction closing", function() {

    beforeEach(async () => {
      // Time travel
      await timeTravelToListingWindow(listingId);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
    })

    describe("Revert cases", function() {
      
      it("Should revert if caller is not auction lister or bidder.", async () => {
        await expect(
          marketv2.connect(dummy).closeAuction(listingId)
        ).to.be.revertedWith("Market: must be bidder or auction creator.")
      })

      it("Should revert if listing is not an auction.", async () => {
        const newListingId = await marketv2.totalListings();
        const newTokenId: BigNumber = nftTokenId.add(1);
        await mockNft.connect(protocolAdmin).mint(
          lister.address,
          newTokenId,
          nftTokenSupply,
          ethers.utils.toUtf8Bytes("")
        );
        
        const newListingParams = {...listingParams, tokenId: newTokenId, quantityToList: 1, startTime: 0, listingType: ListingType.Direct};

        await marketv2.connect(lister).createListing(newListingParams);

        await expect(
          marketv2.connect(lister).closeAuction(newListingId)
        ).to.be.revertedWith("Market: listing is not an auction.");
      })

      it("Should revert if the auction duration is not over.", async () => {
        await expect(
          marketv2.connect(lister).closeAuction(listingId)
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
          marketv2.connect(lister).closeAuction(listingId)
        ).to.emit(marketv2, "AuctionClosed")
        .withArgs(
          ...Object.values({
            listingId: listingId,
            closer: lister.address,
            auctionlister: lister.address,
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
              tokenOwner: lister.address,
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
            auctionlister: lister.address,
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
              tokenOwner: lister.address,
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
        
        const listerBalBefore: BigNumber = await erc20Token.balanceOf(lister.address)
        const marketBalBefore: BigNumber = await erc20Token.balanceOf(marketv2.address);

        await marketv2.connect(lister).closeAuction(listingId)

        const listerBalAfter: BigNumber = await erc20Token.balanceOf(lister.address)
        const marketBalAfter: BigNumber = await erc20Token.balanceOf(marketv2.address);

        expect(listerBalAfter).to.equal(listerBalBefore.add(totalOfferAmount))
        expect(marketBalAfter).to.equal(marketBalBefore.sub(totalOfferAmount))
      })

      it("Should transfer auctioned tokens to bidder when called by bidder", async () => {
        const marketBalBefore: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId)
        const buyerBalBefore: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

        await marketv2.connect(buyer).closeAuction(listingId)

        const marketBalAfter: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId)
        const buyerBalAfter: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

        expect(marketBalAfter).to.equal(marketBalBefore.sub(listingParams.quantityToList))
        expect(buyerBalAfter).to.equal(buyerBalBefore.add(listingParams.quantityToList))
      })

      it("Should not affect any currency balances on repeat calls by bidder of lister", async () => {
        await marketv2.connect(lister).closeAuction(listingId)
        await marketv2.connect(buyer).closeAuction(listingId)
        
        const listerBalBefore: BigNumber = await erc20Token.balanceOf(lister.address)
        const marketBalBefore: BigNumber = await erc20Token.balanceOf(marketv2.address);

        await marketv2.connect(lister).closeAuction(listingId)

        const listerBalAfter: BigNumber = await erc20Token.balanceOf(lister.address)
        const marketBalAfter: BigNumber = await erc20Token.balanceOf(marketv2.address);

        expect(listerBalAfter).to.equal(listerBalBefore)
        expect(marketBalBefore).to.equal(marketBalAfter)
      })

      it("Should not affect any token balances on repeat calls by bidder of lister", async () => {
        await marketv2.connect(lister).closeAuction(listingId)
        await marketv2.connect(buyer).closeAuction(listingId)
        
        const marketBalBefore: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId)
        const buyerBalBefore: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

        await marketv2.connect(buyer).closeAuction(listingId)

        const marketBalAfter: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId)
        const buyerBalAfter: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

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
        await marketv2.connect(lister).closeAuction(listingId)

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