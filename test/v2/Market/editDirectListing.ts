import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155 } from "../../../typechain/MockERC1155";
import { MarketWithAuction, ListingParametersStruct, ListingStruct } from "../../../typechain/MarketWithAuction";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Edit listing: direct listing", function () {
  
  // Constants
  const NATIVE_TOKEN_ADDRESS: string = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let lister: SignerWithAddress;

  // Contracts
  let marketv2: MarketWithAuction;
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

  // Semantic helpers
  const mintNftToLister = async () => await mockNft.connect(protocolAdmin).mint(
    lister.address,
    nftTokenId,
    nftTokenSupply,
    ethers.utils.toUtf8Bytes("")
  );

  const approveMarketToTransferTokens = async (toApprove: boolean) => await mockNft.connect(lister).setApprovalForAll(marketv2.address, toApprove);

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
      
      secondsUntilStartTime: BigNumber.from(100),
      secondsUntilEndTime: BigNumber.from(1000),

      quantityToList: nftTokenSupply,
      currencyToAccept: NATIVE_TOKEN_ADDRESS,

      reservePricePerToken: ethers.utils.parseEther("0.1"),
      buyoutPricePerToken: ethers.utils.parseEther("0.2"),
      tokensPerBuyer: BigNumber.from(1),

      listingType: ListingType.Direct
    }

    // Setup: `lister` lists nft for sale in a direct listing.
    await marketv2.connect(lister).createListing(listingParams)
  });

  describe("Revert cases", function() {
    it("Should revert if lister edits quantity to an amount they don't own or have approved for transfer", async () => {
      const invalidNewQuantity: BigNumber = nftTokenSupply.add(1);

      // Invalid behaviour: `lister` lists more NFTs for sale than they own.
      await expect(
        marketv2.connect(lister).editListingParametrs(
          listingId,
          invalidNewQuantity,
          listingParams.reservePricePerToken,
          listingParams.buyoutPricePerToken,
          listingParams.tokensPerBuyer,
          listingParams.currencyToAccept,
          listingParams.secondsUntilStartTime,
          listingParams.secondsUntilEndTime
        )
      ).to.be.revertedWith("Market: must own and approve to transfer tokens.")
    })
  })

  describe("Events", function() {
    it("Should emit ListingUpdate with new listing info", async () => {
      const newTokensPerBuyer: BigNumber = (listingParams.tokensPerBuyer as BigNumber).add(1);
      const newSecondsUntilStartTime: BigNumber = BigNumber.from(1000);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(5000);

      const timeStampOnEditListing: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp + 1);

      await expect(
        marketv2.connect(lister).editListingParametrs(
          listingId,
          listingParams.quantityToList,
          listingParams.reservePricePerToken,
          listingParams.buyoutPricePerToken,
          newTokensPerBuyer,
          listingParams.currencyToAccept,
          newSecondsUntilStartTime,
          newSecondsUntilEndTime
        )
      ).to.emit(marketv2, "ListingUpdate")
      .withArgs(
        lister.address,
        listingId,
        Object.values({
          listingId: listingId,
          tokenOwner: lister.address,
          assetContract: mockNft.address,
          tokenId: listingParams.tokenId,
          startTime: timeStampOnEditListing.add(newSecondsUntilStartTime),
          endTime: timeStampOnEditListing.add(newSecondsUntilEndTime),
          quantity: listingParams.quantityToList,
          currency: listingParams.currencyToAccept,
          reservePricePerToken: listingParams.reservePricePerToken,
          buyoutPricePerToken: listingParams.buyoutPricePerToken,
          tokensPerBuyer: newTokensPerBuyer,
          tokenType: TokenType.ERC1155,
          listingType: ListingType.Direct
        })
      );
    })
  })

  describe("Balances", function() {
    it("Should not affect token balance on editing listing quantity", async () => {
      
      const newListingQuantity = (listingParams.quantityToList as BigNumber).sub(1);
      
      const balBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId)
      await marketv2.connect(lister).editListingParametrs(
        listingId,
        newListingQuantity,
        listingParams.reservePricePerToken,
        listingParams.buyoutPricePerToken,
        listingParams.tokensPerBuyer,
        listingParams.currencyToAccept,
        listingParams.secondsUntilStartTime,
        listingParams.secondsUntilEndTime
      )
      const balAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId)

      expect(balAfter).to.equal(balBefore);
    })
  })

  describe("Contract state", function() {
    it("Should store the edited listing state", async () => {
      const newTokensPerBuyer: BigNumber = (listingParams.tokensPerBuyer as BigNumber).add(1);
      const newSecondsUntilStartTime: BigNumber = BigNumber.from(1000);
      const newSecondsUntilEndTime: BigNumber = BigNumber.from(6000);

      const timeStampOnEditListing: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp + 1);

      await marketv2.connect(lister).editListingParametrs(
        listingId,
        listingParams.quantityToList,
        listingParams.reservePricePerToken,
        listingParams.buyoutPricePerToken,
        newTokensPerBuyer,
        listingParams.currencyToAccept,
        newSecondsUntilStartTime,
        newSecondsUntilEndTime
      )

      const listing: ListingStruct = await marketv2.listings(listingId);

      expect(listing.listingId).to.equal(listingId);
      expect(listing.tokenOwner).to.equal(lister.address);
      expect(listing.assetContract).to.equal(mockNft.address);
      expect(listing.tokenId).to.equal(listingParams.tokenId);    
      expect(listing.startTime).to.equal(timeStampOnEditListing.add(newSecondsUntilStartTime))
      expect(listing.endTime).to.equal(timeStampOnEditListing.add(newSecondsUntilEndTime))
      expect(listing.quantity).to.equal(listingParams.quantityToList)
      expect(listing.currency).to.equal(listingParams.currencyToAccept);
      expect(listing.reservePricePerToken).to.equal(listingParams.reservePricePerToken);
      expect(listing.buyoutPricePerToken).to.equal(listingParams.buyoutPricePerToken);
      expect(listing.tokensPerBuyer).to.equal(newTokensPerBuyer);
      expect(listing.tokenType).to.equal(TokenType.ERC1155)
      expect(listing.listingType).to.equal(ListingType.Direct);
    })
  })
});
