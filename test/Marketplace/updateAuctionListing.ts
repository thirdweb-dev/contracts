import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155 } from "../../typechain/MockERC1155";
import { Marketplace, ListingParametersStruct, ListingStruct } from "../../typechain/Marketplace";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";

use(solidity);

describe("Edit listing: direct listing", function () {
  // Constants
  const NATIVE_TOKEN_ADDRESS: string = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let lister: SignerWithAddress;

  // Contracts
  let marketv2: Marketplace;
  let mockNft: MockERC1155;

  // MockERC1155: `mint` parameters
  const nftTokenId: BigNumber = BigNumber.from(1);
  const nftTokenSupply: BigNumber = BigNumber.from(Math.floor(1 + Math.random()) * 100);

  // Market: `createListing` params
  enum ListingType {
    Direct,
    Auction,
  }
  enum TokenType {
    ERC1155,
    ERC721,
  }
  let listingId: BigNumber;
  let listingParams: ListingParametersStruct;

  // Semantic helpers
  const mintNftToLister = async () =>
    await mockNft.connect(protocolAdmin).mint(lister.address, nftTokenId, nftTokenSupply, ethers.utils.toUtf8Bytes(""));

  const approveMarketToTransferTokens = async (toApprove: boolean) =>
    await mockNft.connect(lister).setApprovalForAll(marketv2.address, toApprove);

  const timeTravelToListingWindow = async (listingId: BigNumber) => {
    // Time travel
    const listingStart: string = (await marketv2.listings(listingId)).startTime.toString();
    await ethers.provider.send("evm_mine", [parseInt(listingStart)]);
  };

  const timeTravelToAfterListingWindow = async (listingId: BigNumber) => {
    // Time travel
    const listingEnd: string = (await marketv2.listings(listingId)).endTime.toString();
    await ethers.provider.send("evm_mine", [parseInt(listingEnd)]);
  };

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, lister] = signers;
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

      startTime: BigNumber.from((await ethers.provider.getBlock("latest")).timestamp).add(100),
      secondsUntilEndTime: BigNumber.from(1000),

      quantityToList: nftTokenSupply,
      currencyToAccept: NATIVE_TOKEN_ADDRESS,

      reservePricePerToken: ethers.utils.parseEther("0.1"),
      buyoutPricePerToken: ethers.utils.parseEther("0.2"),

      listingType: ListingType.Auction,
    };

    // Setup: `lister` lists nft for sale in a direct listing.
    await marketv2.connect(lister).createListing(listingParams);
  });

  describe("Revert cases", function () {
    it("Should revert if the auction has already started", async () => {
      await timeTravelToListingWindow(listingId);

      const newStartTime: BigNumber = (listingParams.startTime as BigNumber).add(100);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(5000);

      await expect(
        marketv2
          .connect(lister)
          .updateListing(
            listingId,
            listingParams.quantityToList,
            listingParams.reservePricePerToken,
            listingParams.buyoutPricePerToken,
            listingParams.currencyToAccept,
            newStartTime,
            newSecondsUntilEndTime,
          ),
      ).to.be.revertedWith("Marketplace: auction already started.");
    });

    it("Should revert if lister edits quantity to an amount they don't own or have approved for transfer", async () => {
      const invalidNewQuantity: BigNumber = nftTokenSupply.add(1);

      // Invalid behaviour: `lister` lists more NFTs for sale than they own.
      await expect(
        marketv2
          .connect(lister)
          .updateListing(
            listingId,
            invalidNewQuantity,
            listingParams.reservePricePerToken,
            listingParams.buyoutPricePerToken,
            listingParams.currencyToAccept,
            listingParams.startTime,
            listingParams.secondsUntilEndTime,
          ),
      ).to.be.revertedWith("Marketplace: insufficient token balance or approval.");
    });

    it("Should revert if caller is not auction creator", async () => {
      const newStartTime: BigNumber = (listingParams.startTime as BigNumber).add(100);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(5000);

      await expect(
        marketv2
          .connect(protocolAdmin)
          .updateListing(
            listingId,
            listingParams.quantityToList,
            listingParams.reservePricePerToken,
            listingParams.buyoutPricePerToken,
            listingParams.currencyToAccept,
            newStartTime,
            newSecondsUntilEndTime,
          ),
      ).to.be.revertedWith("Marketplace: caller is not listing creator.");
    });
  });

  describe("Events", function () {
    it("Should emit AuctionClosed if new listing quantity is 0", async () => {
      const newQuantity: BigNumber = BigNumber.from(0);
      const newStartTime: BigNumber = (listingParams.startTime as BigNumber).add(100);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(5000);

      await expect(
        marketv2
          .connect(lister)
          .updateListing(
            listingId,
            newQuantity,
            listingParams.reservePricePerToken,
            listingParams.buyoutPricePerToken,
            listingParams.currencyToAccept,
            newStartTime,
            newSecondsUntilEndTime,
          ),
      )
        .to.emit(marketv2, "AuctionClosed")
        .withArgs(
          ...Object.values({
            listingId: listingId,
            closer: lister.address,
            cancelled: true,
            auctionCreator: lister.address,
            winningBidder: ethers.constants.AddressZero,
          }),
        );
    });

    it("Should emit ListingUpdate with new listing info, if new listing quantity is not 0", async () => {
      const newStartTime: BigNumber = (listingParams.startTime as BigNumber).add(100);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(5000);

      await expect(
        marketv2
          .connect(lister)
          .updateListing(
            listingId,
            listingParams.quantityToList,
            listingParams.reservePricePerToken,
            listingParams.buyoutPricePerToken,
            listingParams.currencyToAccept,
            newStartTime,
            newSecondsUntilEndTime,
          ),
      )
        .to.emit(marketv2, "ListingUpdate")
        .withArgs(listingId, lister.address);
    });
  });

  describe("Balances", function () {
    it("Should update token balance of Marketplace and lister on editing listing quantity", async () => {
      const amountToRemove: BigNumber = BigNumber.from(1);
      const newListingQuantity = (listingParams.quantityToList as BigNumber).sub(amountToRemove);

      const listerBalBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const marketBalBefore: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId);

      await marketv2
        .connect(lister)
        .updateListing(
          listingId,
          newListingQuantity,
          listingParams.reservePricePerToken,
          listingParams.buyoutPricePerToken,
          listingParams.currencyToAccept,
          listingParams.startTime,
          listingParams.secondsUntilEndTime,
        );
      const listerBalAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const marketBalAfter: BigNumber = await mockNft.balanceOf(marketv2.address, nftTokenId);

      expect(listerBalAfter).to.equal(listerBalBefore.add(amountToRemove));
      expect(marketBalAfter).to.equal(marketBalBefore.sub(amountToRemove));
    });
  });

  describe("Contract state", function () {
    it("Should cancel auction i.e. delete listing info if new quantity is 0", async () => {
      const newQuantity: BigNumber = BigNumber.from(0);
      const newStartTime: BigNumber = (listingParams.startTime as BigNumber).add(100);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(5000);

      await marketv2
        .connect(lister)
        .updateListing(
          listingId,
          newQuantity,
          listingParams.reservePricePerToken,
          listingParams.buyoutPricePerToken,
          listingParams.currencyToAccept,
          newStartTime,
          newSecondsUntilEndTime,
        );

      const listing: ListingStruct = await marketv2.listings(listingId);

      expect(listing.tokenOwner).to.equal(ethers.constants.AddressZero);
    });

    it("Should store the edited listing state", async () => {
      const amountToRemove: BigNumber = BigNumber.from(1);
      const newListingQuantity = (listingParams.quantityToList as BigNumber).sub(amountToRemove);

      const newStartTime: BigNumber = (listingParams.startTime as BigNumber).add(100);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(6000);

      await marketv2
        .connect(lister)
        .updateListing(
          listingId,
          newListingQuantity,
          listingParams.reservePricePerToken,
          listingParams.buyoutPricePerToken,
          listingParams.currencyToAccept,
          newStartTime,
          newSecondsUntilEndTime,
        );

      const listing: ListingStruct = await marketv2.listings(listingId);

      expect(listing.listingId).to.equal(listingId);
      expect(listing.tokenOwner).to.equal(lister.address);
      expect(listing.assetContract).to.equal(mockNft.address);
      expect(listing.tokenId).to.equal(listingParams.tokenId);
      expect(listing.startTime).to.equal(newStartTime);
      expect(listing.endTime).to.equal(newStartTime.add(newSecondsUntilEndTime));
      expect(listing.quantity).to.equal(newListingQuantity);
      expect(listing.currency).to.equal(listingParams.currencyToAccept);
      expect(listing.reservePricePerToken).to.equal(listingParams.reservePricePerToken);
      expect(listing.buyoutPricePerToken).to.equal(listingParams.buyoutPricePerToken);
      expect(listing.tokenType).to.equal(TokenType.ERC1155);
      expect(listing.listingType).to.equal(ListingType.Auction);
    });
  });
});
