import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155 } from "../../../../typechain/MockERC1155";
import { Marketplace, ListingParametersStruct, ListingStruct } from "../../../../typechain/Marketplace";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";

use(solidity);

describe("Offer with native token: direct listing", function () {
  // Constants
  const NATIVE_TOKEN_ADDRESS: string = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let lister: SignerWithAddress;
  let buyer: SignerWithAddress;
  let dummy: SignerWithAddress;

  // Contracts
  let marketv2: Marketplace;
  let mockNft: MockERC1155;

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
  let currencyForOffer: string;
  let offerPricePerToken: BigNumber = ethers.utils.parseEther("1");

  // Semantic helpers
  const mintNftToLister = async () => await mockNft.connect(protocolAdmin).mint(
    lister.address,
    nftTokenId,
    nftTokenSupply,
    ethers.utils.toUtf8Bytes("")
  );

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
      currencyToAccept: NATIVE_TOKEN_ADDRESS,

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
      const sender = dummy;
      const receiver = buyer; // Who the actual sender/receiver is doesn't matter.
      const senderBal = await ethers.provider.getBalance(sender.address);
      await sender.sendTransaction({
        to: receiver.address,
        value: senderBal.sub(offerPricePerToken.mul(quantityWanted))
      })

      await expect(
        marketv2.connect(sender).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")
    })
  })

  describe("Events", function() {

    beforeEach(async () => {
      await timeTravelToListingWindow(listingId);
    })

    it("Should emit NewOffer with the relevant offer info", async () => {
      
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

      const creatorBalBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalBefore: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken)

      const creatorBalAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalAfter: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      expect(creatorBalAfter).to.equal(creatorBalBefore)
      expect(buyerBalAfter).to.equal(buyerBalBefore)
    })

    it("Should not affect currency balances when an offer is made", async () => {

      const listerBalBefore: BigNumber = await ethers.provider.getBalance(lister.address);
      const buyerBalBefore: BigNumber = await ethers.provider.getBalance(buyer.address);

      const gasPrice: BigNumber = ethers.utils.parseUnits("1", "gwei")
      const tx = await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken, { gasPrice })
      const gasPaid: BigNumber = gasPrice.mul((await  tx.wait()).gasUsed);

      const listerBalAfter: BigNumber = await ethers.provider.getBalance(lister.address);
      const buyerBalAfter: BigNumber = await ethers.provider.getBalance(buyer.address);

      expect(listerBalAfter).to.equal(listerBalBefore);
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(gasPaid))
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
