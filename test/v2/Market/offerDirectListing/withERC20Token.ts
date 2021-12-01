import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155 } from "../../../../typechain/MockERC1155";
import { Coin } from "../../../../typechain/Coin";
import { MarketWithAuction, ListingParametersStruct, ListingStruct } from "../../../../typechain/MarketWithAuction";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";

use(solidity);

describe("Offer with ERC20 token: direct listing", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let lister: SignerWithAddress;
  let buyer: SignerWithAddress;
  let dummy: SignerWithAddress;

  // Contracts
  let marketv2: MarketWithAuction;
  let mockNft: MockERC1155;
  let erc20Token: Coin;

  // MockERC1155: `mint` parameters
  const nftTokenId: BigNumber = BigNumber.from(1);
  const nftTokenSupply: BigNumber = BigNumber.from(
    Math.floor((1 + Math.random())) * 100
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

  // Semantic helpers
  const mintNftToLister = async () => await mockNft.connect(protocolAdmin).mint(
    lister.address,
    nftTokenId,
    nftTokenSupply,
    ethers.utils.toUtf8Bytes("")
  );

  const mintERC20ToBuyer = async (amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(protocolAdmin).mint(buyer.address, amount);

    // Approve Market to transfer currency
    await erc20Token.connect(buyer).approve(marketv2.address, amount);
  }

  const approveMarketToTransferTokens = async (toApprove: boolean) => await mockNft.connect(lister).setApprovalForAll(marketv2.address, toApprove);

  const timeTravelToListingWindow = async (listingId: BigNumber) => {
    const listingStartTime: number = (await marketv2.listings(listingId)).startTime.toNumber();

    await ethers.provider.send("evm_setNextBlockTimestamp", [listingStartTime]);
    await ethers.provider.send("evm_mine", []);
  }

  const timeTravelToAfterListingWindow = async (listingId: BigNumber) => {
    const listingEndTime: number = (await marketv2.listings(listingId)).endTime.toNumber();

    await ethers.provider.send("evm_setNextBlockTimestamp", [listingEndTime]);
    await ethers.provider.send("evm_mine", []);
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
      
      secondsUntilStartTime: BigNumber.from(100),
      secondsUntilEndTime: BigNumber.from(1000),

      quantityToList: nftTokenSupply,
      currencyToAccept: erc20Token.address,

      reservePricePerToken: ethers.utils.parseEther("0.1"),
      buyoutPricePerToken: ethers.utils.parseEther("0.2"),

      listingType: ListingType.Direct
    }

    // Setup: `lister` lists nft for sale in a direct listing.
    await marketv2.connect(lister).createListing(listingParams)

    // Setup: set default `offer` parameters.
    quantityWanted = BigNumber.from(1);
    offerPricePerToken = listingParams.reservePricePerToken as BigNumber;
    currencyForOffer = listingParams.currencyToAccept;

    // Setup: mint some curreny to buyer so they can fulfill the offer made.
    await mintERC20ToBuyer(
      (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
    )
  });

  describe("Revert cases", function() {

    it("Should revert if offer is made outside listing window", async () => {

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
      ).to.be.revertedWith("Market: can only make offers in listing duration.")

      await timeTravelToAfterListingWindow(listingId);

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
      ).to.be.revertedWith("Market: can only make offers in listing duration.")
    })

    it("Should revert if buyer does not own the required amount of currency", async () => {
      
      await timeTravelToListingWindow(listingId);

      // Invalid behaviour: buyer does not own the given amount of currency.
      await erc20Token.connect(buyer).transfer(dummy.address, await erc20Token.balanceOf(buyer.address));

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")
    })

    it("Should revert if buyer has not approved Market to transfer currency", async () => {
      
      await timeTravelToListingWindow(listingId);

      // Invalid behaviour: buyer has not approved Market to transfer currency.
      await erc20Token.connect(buyer).decreaseAllowance(
        marketv2.address,
        await erc20Token.allowance(buyer.address, marketv2.address)
      );

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")
    })
  })

  describe("Events", function() {

    beforeEach(async () => {
      await timeTravelToListingWindow(listingId);
    })

    it("Should emit NewOffer with the relevant offer info", async () => {
      
      /**
       * Hardhat increments block timestamp by 1 on every transaction.
       * So, the timestamp during the `createListing` transaction will be the current timestamp + 1.
      */
      const listing: ListingStruct = await marketv2.listings(listingId);

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
      ).to.emit(marketv2, "NewOffer")
      .withArgs(
        listingId,
        buyer.address,
        Object.values({
          listingId: listingId,
          offeror: buyer.address,
          quantityWanted: quantityWanted,
          currency: currencyForOffer,
          pricePerToken: offerPricePerToken
        }),
        Object.values({
          listingId: listingId,
          tokenOwner: lister.address,
          assetContract: listingParams.assetContract,
          tokenId: listingParams.tokenId,
          startTime: listing.startTime,
          endTime: listing.endTime,
          quantity: listingParams.quantityToList,
          currency: listingParams.currencyToAccept,
          reservePricePerToken: listingParams.reservePricePerToken,
          buyoutPricePerToken: listingParams.buyoutPricePerToken,
          tokenType: TokenType.ERC1155,
          listingType: ListingType.Direct
        })
      )
    })
  })

  describe("Balances", function() {

    beforeEach(async () => {
      await timeTravelToListingWindow(listingId);
    })

    it("Should not affect NFT token balances when an offer is made", async () => {

      const listerBalBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalBefore: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)

      const listerBalAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalAfter: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      expect(listerBalAfter).to.equal(listerBalBefore)
      expect(buyerBalAfter).to.equal(buyerBalBefore)
    })

    it("Should not affect currency balances when an offer is made", async () => {

      const listerBalBefore: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalBefore: BigNumber = await erc20Token.balanceOf(buyer.address);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)

      const listerBalAfter: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalAfter: BigNumber = await erc20Token.balanceOf(buyer.address);

      expect(listerBalAfter).to.equal(listerBalBefore)
      expect(buyerBalAfter).to.equal(buyerBalBefore)
    })
  })

  describe("Contract state", function() {

    beforeEach(async () => {
      await timeTravelToListingWindow(listingId);
    })
    
    it("Should store the offer info", async () => {

      await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
      
      const offer = await marketv2.offers(listingId, buyer.address);

      expect(offer.listingId).to.equal(listingId)
      expect(offer.offeror).to.equal(buyer.address)
      expect(offer.quantityWanted).to.equal(quantityWanted)
      expect(offer.pricePerToken).to.equal(offerPricePerToken);      
    })
  })
});
