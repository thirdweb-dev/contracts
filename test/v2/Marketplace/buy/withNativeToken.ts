import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155Royalty } from "../../../../typechain/MockERC1155Royalty";
import { ProtocolControl } from "../../../../typechain/ProtocolControl";
import { WETH9 } from "../../../../typechain/WETH9";
import { Marketplace, ListingParametersStruct, ListingStruct } from "../../../../typechain/Marketplace";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";

use(solidity);

describe("Buy: direct listing", function () {
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
  let mockNft: MockERC1155Royalty;
  let weth: WETH9;
  let protocolControl: ProtocolControl;

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
  let totalPriceToPay: BigNumber;

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
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    marketv2 = contracts.marketv2;
    protocolControl = contracts.protocolControl;
    weth = contracts.weth;
    mockNft = await ethers.getContractFactory("MockERC1155Royalty").then(f => f.connect(protocolAdmin).deploy(protocolControl.address));

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

    // Setup: set default `buy` parameters.
    quantityWanted = BigNumber.from(1);
    totalPriceToPay = quantityWanted.mul(listingParams.buyoutPricePerToken);
  });

  describe("Revert cases", function() {

    it("Should revert if listing is an auction", async () => {
      const newListingId = await marketv2.totalListings();
      const newListingParams = {...listingParams, listingType: ListingType.Auction};

      await marketv2.connect(lister).createListing(newListingParams);
      

      await expect(
        marketv2.connect(buyer).buy(newListingId, quantityWanted, { value: totalPriceToPay })
      ).to.be.revertedWith("Marketplace: cannot buy from listing.");
    })

    it("Should revert if quantity to buy is 0", async () => {
      const zeroQuantityWanted: BigNumber = BigNumber.from(0);

      await expect(
        marketv2.connect(buyer).buy(listingId, zeroQuantityWanted, { value: 0 })
      ).to.be.revertedWith("Marketplace: buying invalid amount of tokens.");      
    })

    it("Should revert if listing has no tokens left", async () => {
      const newListingQuantity: BigNumber = BigNumber.from(0);
      
      await marketv2.connect(lister).updateListing(
        listingId,
        newListingQuantity,
        listingParams.reservePricePerToken,
        listingParams.buyoutPricePerToken,
        listingParams.currencyToAccept,
        listingParams.startTime,
        listingParams.secondsUntilEndTime
      )

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay })
      ).to.be.revertedWith("Marketplace: buying invalid amount of tokens.");      
    })

    it("Should revert if listing window has passed", async () => {
      await timeTravelToAfterListingWindow(listingId);

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay })
      ).to.be.revertedWith("Marketplace: not within sale window.");      
    })

    it("Should revert if lister does not own tokens listed", async () => {
      // Transfer away tokens
      await mockNft.connect(lister).safeTransferFrom(
        lister.address, dummy.address, nftTokenId, await mockNft.balanceOf(lister.address, nftTokenId), ethers.utils.toUtf8Bytes("")
      );

      await timeTravelToListingWindow(listingId)

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay })
      ).to.be.revertedWith("Marketplace: insufficient token balance or approval.");
    })

    it("Should revert if lister has not approved market to transfer tokens", async () => {
      
      await timeTravelToListingWindow(listingId)
      
      // Remove transfer approval
      await mockNft.connect(lister).setApprovalForAll(marketv2.address, false);

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay })
      ).to.be.revertedWith("Marketplace: insufficient token balance or approval.");
    })
  })

  describe("Events", function() {

    beforeEach(async () => {

      // Time travel
      await timeTravelToListingWindow(listingId)
    })

    it("Should emit NewDirectSale with the sale info", async () => {

      const quantityWanted: number = 1;
      
      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay })
      ).to.emit(marketv2, "NewSale")
      .withArgs(
        ...Object.values({
          listingId: listingId,
          assetContract: mockNft.address,
          lister: lister.address,          
          buyer: buyer.address,
          quantityBought: quantityWanted,
          totalOfferAmount: (listingParams.buyoutPricePerToken as BigNumber).mul(quantityWanted)
        })
      )
    })
  })

  describe("Balances", function() {

    beforeEach(async () => {

      // Time travel
      await timeTravelToListingWindow(listingId)
    })

    it("Should transfer tokens bought from lister to buyer", async () => {
      const quantityWanted: number = 1;

      const listerBalBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalBefore: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      await marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay })

      const listerBalAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalAfter: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      expect(listerBalAfter).to.equal(listerBalBefore.sub(quantityWanted))
      expect(buyerBalAfter).to.equal(buyerBalBefore.add(quantityWanted))
    })

    it("Should transfer currency from buyer to lister", async () => {

      // No fees or royalty set up.
      const listerBalBefore: BigNumber = await ethers.provider.getBalance(lister.address);
      const buyerBalBefore: BigNumber = await ethers.provider.getBalance(buyer.address);

      const gasPrice: BigNumber = ethers.utils.parseUnits("10", "gwei")
      const txReceipt = await (await marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay, gasPrice })).wait()
      const gasUesd: BigNumber = txReceipt.gasUsed;
      const gasPaid: BigNumber = gasPrice.mul(gasUesd);

      const listerBalAfter: BigNumber = await ethers.provider.getBalance(lister.address);
      const buyerBalAfter: BigNumber = await ethers.provider.getBalance(buyer.address);

      expect(listerBalAfter).to.equal(listerBalBefore.add(totalPriceToPay))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(totalPriceToPay.add(gasPaid)))
    })

    it("Should distribute sale value to the relevant stake holders", async () => {
      const royaltyTreasury: string = await protocolControl.getRoyaltyTreasury(marketv2.address);

      // Set a market fee
      await marketv2.connect(protocolAdmin).setMarketFeeBps(500) // 5%
      // Set royalty on listed tokens
      await mockNft.connect(protocolAdmin).setRoyaltyBps(500); // 5%
      
      const marketCut: BigNumber = totalPriceToPay.mul(500).div(10000);
      const tokenRoyalty: BigNumber = totalPriceToPay.mul(500).div(10000);

      const royaltyTreasuryBefore: BigNumber = await ethers.provider.getBalance(royaltyTreasury);
      const listerBalBefore: BigNumber = await ethers.provider.getBalance(lister.address);
      const buyerBalBefore: BigNumber = await ethers.provider.getBalance(buyer.address);

      const gasPrice: BigNumber = ethers.utils.parseUnits("10", "gwei")
      const txReceipt = await (await marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay, gasPrice })).wait()
      const gasUesd: BigNumber = txReceipt.gasUsed;
      const gasPaid: BigNumber = gasPrice.mul(gasUesd);

      const royaltyTreasuryAfter: BigNumber = await ethers.provider.getBalance(royaltyTreasury);
      const listerBalAfter: BigNumber = await ethers.provider.getBalance(lister.address);
      const buyerBalAfter: BigNumber = await ethers.provider.getBalance(buyer.address);

      expect(royaltyTreasuryAfter).to.equal(royaltyTreasuryBefore.add(marketCut.add(tokenRoyalty)))
      expect(listerBalAfter).to.equal(listerBalBefore.add(totalPriceToPay.sub(marketCut.add(tokenRoyalty))))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(totalPriceToPay.add(gasPaid)))
      
    })
  })

  describe("Contract state", function() {

    beforeEach(async () => {

      // Time travel
      await timeTravelToListingWindow(listingId)
    })

    it("Should decrease the quantity available in the listing", async () => {
      const quantityWanted: number = 1;

      await marketv2.connect(buyer).buy(listingId, quantityWanted, { value: totalPriceToPay })

      const listing = await marketv2.listings(listingId);

      expect(listing.quantity).to.equal((listingParams.quantityToList as BigNumber).sub(quantityWanted));
    })
  })
});
