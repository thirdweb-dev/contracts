import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155 } from "../../../typechain/MockERC1155";
import { Coin } from "../../../typechain/Coin";
import { Marketplace, ListingParametersStruct, ListingStruct } from "../../../typechain/Marketplace";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Accept offer: direct listing", function () {
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

  // Market: `offer` params
  let quantityWanted: BigNumber;
  let offerPricePerToken: BigNumber;
  let currencyForOffer: string;

  // Semantic helpers
  const mintNftToLister = async () =>
    await mockNft.connect(protocolAdmin).mint(lister.address, nftTokenId, nftTokenSupply, ethers.utils.toUtf8Bytes(""));

  const mintERC20ToBuyer = async (amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(protocolAdmin).mint(buyer.address, amount);

    // Approve Market to transfer currency
    await erc20Token.connect(buyer).approve(marketv2.address, amount);
  };

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

      startTime: BigNumber.from((await ethers.provider.getBlock("latest")).timestamp).add(100),
      secondsUntilEndTime: BigNumber.from(1000),

      quantityToList: nftTokenSupply,
      currencyToAccept: erc20Token.address,

      reservePricePerToken: ethers.utils.parseEther("0.1"),
      buyoutPricePerToken: ethers.utils.parseEther("0.2"),

      listingType: ListingType.Direct,
    };

    // Setup: `lister` lists nft for sale in a direct listing.
    await marketv2.connect(lister).createListing(listingParams);

    // Setup: set default `offer` parameters.
    quantityWanted = BigNumber.from(1);
    offerPricePerToken = listingParams.reservePricePerToken as BigNumber;
    currencyForOffer = listingParams.currencyToAccept;

    // Setup: mint some curreny to buyer so they can fulfill the offer made.
    await mintERC20ToBuyer((listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList));

    // Setup: buyer makes an offer to the direct listing.
    await timeTravelToListingWindow(listingId);
    await marketv2.connect(buyer).offer(listingId, quantityWanted, currencyForOffer, offerPricePerToken);
  });

  describe("Revert cases", function () {
    it("Should revert if listing is an auction", async () => {
      const newListingId = await marketv2.totalListings();
      const newListingParams = { ...listingParams, listingType: ListingType.Auction };

      await marketv2.connect(lister).createListing(newListingParams);
      await marketv2.connect(buyer).offer(newListingId, quantityWanted, currencyForOffer, offerPricePerToken);

      await expect(marketv2.connect(lister).acceptOffer(newListingId, buyer.address)).to.be.revertedWith(
        "Marketplace: cannot buy from listing.",
      );
    });

    it("Should revert if offer quantity is 0", async () => {
      const zeroQuantityWanted: BigNumber = BigNumber.from(0);
      await marketv2.connect(buyer).offer(listingId, zeroQuantityWanted, currencyForOffer, offerPricePerToken);

      await expect(marketv2.connect(lister).acceptOffer(listingId, buyer.address)).to.be.revertedWith(
        "Marketplace: buying invalid amount of tokens.",
      );
    });

    it("Should revert if listing has no tokens left", async () => {
      const newListingQuantity: BigNumber = BigNumber.from(0);

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

      await expect(marketv2.connect(lister).acceptOffer(listingId, buyer.address)).to.be.revertedWith(
        "Marketplace: buying invalid amount of tokens.",
      );
    });

    it("Should revert if listing window has passed", async () => {
      await timeTravelToAfterListingWindow(listingId);

      await expect(marketv2.connect(lister).acceptOffer(listingId, buyer.address)).to.be.revertedWith(
        "Marketplace: not within sale window.",
      );
    });

    it("Should revert if lister does not own tokens listed", async () => {
      // Transfer away tokens
      await mockNft
        .connect(lister)
        .safeTransferFrom(
          lister.address,
          dummy.address,
          nftTokenId,
          await mockNft.balanceOf(lister.address, nftTokenId),
          ethers.utils.toUtf8Bytes(""),
        );

      await expect(marketv2.connect(lister).acceptOffer(listingId, buyer.address)).to.be.revertedWith(
        "Marketplace: insufficient token balance or approval.",
      );
    });

    it("Should revert if lister has not approved market to transfer tokens", async () => {
      // Remove transfer approval
      await mockNft.connect(lister).setApprovalForAll(marketv2.address, false);

      await expect(marketv2.connect(lister).acceptOffer(listingId, buyer.address)).to.be.revertedWith(
        "Marketplace: insufficient token balance or approval.",
      );
    });

    it("Should revert if offeror's currency balance is less than offer amount", async () => {
      // Transfer away currency
      const buyerBal: BigNumber = await erc20Token.balanceOf(buyer.address);
      await erc20Token.connect(buyer).transfer(dummy.address, buyerBal);

      await expect(marketv2.connect(lister).acceptOffer(listingId, buyer.address)).to.be.revertedWith(
        "Marketplace: insufficient currency balance or allowance.",
      );
    });
  });

  describe("Events", function () {
    it("Should emit NewSale with relevan sale info", async () => {
      await expect(marketv2.connect(lister).acceptOffer(listingId, buyer.address))
        .to.emit(marketv2, "NewSale")
        .withArgs(
          ...Object.values({
            listingId: listingId,
            assetContract: mockNft.address,
            lister: lister.address,
            buyer: buyer.address,
            quantityBought: quantityWanted,
            totalOfferAmount: offerPricePerToken.mul(quantityWanted),
          }),
        );
    });
  });

  describe("Balances", function () {
    it("Should payout the lister with the offer amount", async () => {
      const listerBalBefore: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalBefore: BigNumber = await erc20Token.balanceOf(buyer.address);

      await marketv2.connect(lister).acceptOffer(listingId, buyer.address);

      const listerBalAfter: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalAfter: BigNumber = await erc20Token.balanceOf(buyer.address);

      expect(listerBalAfter).to.equal(listerBalBefore.add(offerPricePerToken.mul(quantityWanted)));
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(offerPricePerToken.mul(quantityWanted)));
    });

    it("Should transfer the given amount listed tokens to offeror", async () => {
      const listerBalBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalBefore: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      await marketv2.connect(lister).acceptOffer(listingId, buyer.address);

      const listerBalAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalAfter: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      expect(listerBalAfter).to.equal(listerBalBefore.sub(quantityWanted));
      expect(buyerBalAfter).to.equal(buyerBalBefore.add(quantityWanted));
    });
  });

  describe("Contract state", function () {
    it("Should update the listing quantity", async () => {
      const listingQuantityBefore: BigNumber = (await marketv2.listings(listingId)).quantity;
      await marketv2.connect(lister).acceptOffer(listingId, buyer.address);
      const listingQuantityAfter: BigNumber = (await marketv2.listings(listingId)).quantity;

      expect(listingQuantityAfter).to.equal(listingQuantityBefore.sub(quantityWanted));
    });

    it("Should reset the offer made", async () => {
      await marketv2.connect(lister).acceptOffer(listingId, buyer.address);

      const offer = await marketv2.offers(listingId, buyer.address);

      expect(offer.pricePerToken).to.equal(0);
      expect(offer.quantityWanted).to.equal(0);
    });
  });
});
