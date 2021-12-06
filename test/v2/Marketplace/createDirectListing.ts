import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155 } from "../../../typechain/MockERC1155";
import { Marketplace, ListingParametersStruct, ListingStruct } from "../../../typechain/Marketplace";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("List token for sale: Direct Listing", function () {
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

      listingType: ListingType.Direct,
    };
  });

  describe("Revert cases", function () {
    it("Should revert if listing zero quantity.", async () => {
      // Invalid behaviour: listing `0` of the tokens for sale.
      const incorrectParams = { ...listingParams, quantityToList: 0 };

      await expect(marketv2.connect(lister).createListing(incorrectParams)).to.be.revertedWith(
        "Marketplace: insufficient token balance or approval.",
      );
    });

    it("Should revert if lister does not own the amount of token to list.", async () => {
      // Invalid behaviour: caller does not own the given amount of tokens being listed.
      await expect(marketv2.connect(protocolAdmin).createListing(listingParams)).to.be.revertedWith(
        "Marketplace: insufficient token balance or approval.",
      );
    });

    it("Should revert if market doesn't have lister's approval to transfer tokens", async () => {
      // Invalid behaviour: `lister` does not approve Market to transfer tokens listed.
      await approveMarketToTransferTokens(false);

      await expect(marketv2.connect(lister).createListing(listingParams)).to.be.revertedWith(
        "Marketplace: insufficient token balance or approval.",
      );
    });
  });

  describe("Events", function () {
    it("Should emit NewListing with all relevant info", async () => {
      /**
       * Hardhat increments block timestamp by 1 on every transaction.
       * So, the timestamp during the `createListing` transaction will be the current timestamp + 1.
       */
      // const timeStampOnCreateListing: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp + 1);

      await expect(marketv2.connect(lister).createListing(listingParams))
        .to.emit(marketv2, "NewListing")
        .withArgs(
          listingId,
          mockNft.address,
          lister.address,
          Object.values({
            listingId: listingId,
            tokenOwner: lister.address,
            assetContract: listingParams.assetContract,
            tokenId: listingParams.tokenId,
            startTime: listingParams.startTime,
            endTime: (listingParams.startTime as BigNumber).add(listingParams.secondsUntilEndTime),
            quantity: listingParams.quantityToList,
            currency: listingParams.currencyToAccept,
            reservePricePerToken: listingParams.reservePricePerToken,
            buyoutPricePerToken: listingParams.buyoutPricePerToken,
            tokenType: TokenType.ERC1155,
            listingType: ListingType.Direct,
          }),
        );
    });
  });

  describe("Token balances", function () {
    it("Should not change the lister's token balance", async () => {
      const balBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      await marketv2.connect(lister).createListing(listingParams);
      const balAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);

      expect(balBefore).to.equal(balAfter);
    });
  });

  describe("Contract state", function () {
    it("Should increment the total listings on the contract", async () => {
      const totalListingsBefore: BigNumber = await marketv2.totalListings();
      await marketv2.connect(lister).createListing(listingParams);
      const totalListingAfter: BigNumber = await marketv2.totalListings();

      expect(totalListingAfter.sub(totalListingsBefore)).to.equal(1);
    });

    it("Should store the listing's state", async () => {
      const listingId: BigNumber = await marketv2.totalListings();

      await marketv2.connect(lister).createListing(listingParams);

      const listing: ListingStruct = await marketv2.listings(listingId);

      expect(listing.listingId).to.equal(listingId);
      expect(listing.tokenOwner).to.equal(lister.address);
      expect(listing.assetContract).to.equal(mockNft.address);
      expect(listing.tokenId).to.equal(listingParams.tokenId);
      expect(listing.startTime).to.equal(listingParams.startTime);
      expect(listing.endTime).to.equal((listingParams.startTime as BigNumber).add(listingParams.secondsUntilEndTime));
      expect(listing.quantity).to.equal(listingParams.quantityToList);
      expect(listing.currency).to.equal(listingParams.currencyToAccept);
      expect(listing.reservePricePerToken).to.equal(listingParams.reservePricePerToken);
      expect(listing.buyoutPricePerToken).to.equal(listingParams.buyoutPricePerToken);
      expect(listing.tokenType).to.equal(TokenType.ERC1155);
      expect(listing.listingType).to.equal(ListingType.Direct);
    });
  });
});
