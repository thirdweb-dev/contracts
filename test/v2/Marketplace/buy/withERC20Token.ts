import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { MockERC1155Royalty } from "../../../../typechain/MockERC1155Royalty";
import { Coin } from "../../../../typechain/Coin";
import { ProtocolControl } from "../../../../typechain/ProtocolControl";
import { Marketplace, ListingParametersStruct, ListingStruct } from "../../../../typechain/Marketplace";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";

use(solidity);

describe("Buy: direct listing", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let lister: SignerWithAddress;
  let buyer: SignerWithAddress;
  let dummy: SignerWithAddress;

  // Contracts
  let marketv2: Marketplace;
  let mockNft: MockERC1155Royalty;
  let erc20Token: Coin;
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

  const mintERC20ToBuyer = async (amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(protocolAdmin).mint(buyer.address, amount);

    // Approve Market to transfer currency
    await erc20Token.connect(buyer).approve(marketv2.address, amount);
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
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    marketv2 = contracts.marketv2;
    erc20Token = contracts.coin;
    protocolControl = contracts.protocolControl;
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
      currencyToAccept: erc20Token.address,

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

    it("Should revert if buyer does not own the required amount of currency", async () => {
      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")
    })

    it("Should revert if buyer has not approved Market to transfer currency", async () => {
      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )
      
      // Remove Marketplace's approval to transfer currency.
      await erc20Token.connect(buyer).decreaseAllowance(
        marketv2.address,
        await erc20Token.allowance(buyer.address, marketv2.address)
      )

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")      
    })

    it("Should revert if lister does not own the tokens listed", async () => {
      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )

      // Lister transfers away all tokens
      await mockNft.connect(lister).safeTransferFrom(
        lister.address,
        dummy.address,
        nftTokenId,
        nftTokenSupply,
        ethers.utils.toUtf8Bytes("")
      )

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted)
      ).to.be.revertedWith("Market: cannot buy tokens from this listing.")
    })

    it("Should revert if lister has removed Market's approval to transfer tokens listed", async () => {
      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )

      // Lister removes Market's approval to transfer tokens
      await approveMarketToTransferTokens(false)

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted)
      ).to.be.revertedWith("Market: cannot buy tokens from this listing.")
    })

    it("Should revert if the listing is an auction", async () => {
      const newListingId: BigNumber = await marketv2.totalListings();
      const newListingParams = listingParams;

      newListingParams.listingType = ListingType.Auction;

      await marketv2.connect(lister).createListing(newListingParams)

      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )

      await expect(
        marketv2.connect(buyer).buy(newListingId, quantityWanted)
      ).to.be.revertedWith("Market: cannot buy tokens from this listing.")      
    })

    it("Should revert if buyer tries to buy 0 tokens", async () => {
      const invalidQuantityWanted: BigNumber = BigNumber.from(0);

      // Time travel
      await timeTravelToListingWindow(listingId)

      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )

      await expect(
        marketv2.connect(buyer).buy(listingId, invalidQuantityWanted)
      ).to.be.revertedWith("Market: must buy an appropriate amount of tokens.") 
    })

    it("Should revert if buyer tries to buy more tokens than listed", async () => {

      const invalidQuantityWanted: BigNumber = (listingParams.quantityToList as BigNumber).add(1);

      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(invalidQuantityWanted)
      )

      // Time travel
      await timeTravelToListingWindow(listingId)

      await expect(
        marketv2.connect(buyer).buy(listingId, invalidQuantityWanted)
      ).to.be.revertedWith("Market: must buy an appropriate amount of tokens.")
    })

    it("Should revert if buyer tries to buy tokens outside the listing's sale window", async () => {
      
      // Time travel
      await timeTravelToAfterListingWindow(listingId)

      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted)
      ).to.be.revertedWith("Market: the sale has either not started or closed.")
    })
  })

  describe("Events", function() {

    beforeEach(async () => {

      // Time travel
      await timeTravelToListingWindow(listingId)

      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )
    })

    it("Should emit NewDirectSale with the sale info", async () => {

      const quantityWanted: number = 1;
      const listing: ListingStruct = await marketv2.listings(listingId);

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityWanted)
      ).to.emit(marketv2, "NewDirectSale")
      .withArgs(
        ...Object.values({
          assetContract: mockNft.address,
          seller: lister.address,
          listingId: listingId,
          buyer: buyer.address,
          quantityBought: quantityWanted,
          listing: Object.values({
            listingId: listingId,
            tokenOwner: lister.address,
            assetContract: listingParams.assetContract,
            tokenId: listingParams.tokenId,
            startTime: listing.startTime,
            endTime: listing.endTime,
            quantity: (listingParams.quantityToList as BigNumber).sub(quantityWanted),
            currency: listingParams.currencyToAccept,
            reservePricePerToken: listingParams.reservePricePerToken,
            buyoutPricePerToken: listingParams.buyoutPricePerToken,
            tokenType: TokenType.ERC1155,
            listingType: ListingType.Direct
          })
        })
      )
    })
  })

  describe("Balances", function() {

    beforeEach(async () => {

      // Time travel
      await timeTravelToListingWindow(listingId)

      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )
    })

    it("Should transfer tokens bought from lister to buyer", async () => {
      const quantityWanted: number = 1;

      const listerBalBefore: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalBefore: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      await marketv2.connect(buyer).buy(listingId, quantityWanted)

      const listerBalAfter: BigNumber = await mockNft.balanceOf(lister.address, nftTokenId);
      const buyerBalAfter: BigNumber = await mockNft.balanceOf(buyer.address, nftTokenId);

      expect(listerBalAfter).to.equal(listerBalBefore.sub(quantityWanted))
      expect(buyerBalAfter).to.equal(buyerBalBefore.add(quantityWanted))
    })

    it("Should transfer currency from buyer to lister", async () => {

      // No fees or royalty set up.
      const listerBalBefore: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalBefore: BigNumber = await erc20Token.balanceOf(buyer.address);

      await marketv2.connect(buyer).buy(listingId, quantityWanted)

      const listerBalAfter: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalAfter: BigNumber = await erc20Token.balanceOf(buyer.address);

      expect(listerBalAfter).to.equal(listerBalBefore.add(totalPriceToPay))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(totalPriceToPay))
    })

    it("Should distribute sale value to the relevant stake holders", async () => {
      const royaltyTreasury: string = await protocolControl.getRoyaltyTreasury(marketv2.address);

      // Set a market fee
      await marketv2.connect(protocolAdmin).setMarketFeeBps(500) // 5%
      // Set royalty on listed tokens
      await mockNft.connect(protocolAdmin).setRoyaltyBps(500); // 5%
      
      const marketCut: BigNumber = totalPriceToPay.mul(500).div(10000);
      const tokenRoyalty: BigNumber = totalPriceToPay.mul(500).div(10000);

      const royaltyTreasuryBefore: BigNumber = await erc20Token.balanceOf(royaltyTreasury);
      const listerBalBefore: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalBefore: BigNumber = await erc20Token.balanceOf(buyer.address);

      await marketv2.connect(buyer).buy(listingId, quantityWanted)

      const royaltyTreasuryAfter: BigNumber = await erc20Token.balanceOf(royaltyTreasury);
      const listerBalAfter: BigNumber = await erc20Token.balanceOf(lister.address);
      const buyerBalAfter: BigNumber = await erc20Token.balanceOf(buyer.address);

      expect(royaltyTreasuryAfter).to.equal(royaltyTreasuryBefore.add(marketCut.add(tokenRoyalty)))
      expect(listerBalAfter).to.equal(listerBalBefore.add(totalPriceToPay.sub(marketCut.add(tokenRoyalty))))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(totalPriceToPay))
      
    })
  })

  describe("Contract state", function() {

    beforeEach(async () => {

      // Time travel
      await timeTravelToListingWindow(listingId)

      // Mint currency to buyer
      await mintERC20ToBuyer(
        (listingParams.buyoutPricePerToken as BigNumber).mul(listingParams.quantityToList)
      )
    })

    it("Should decrease the quantity available in the listing", async () => {
      const quantityWanted: number = 1;

      await marketv2.connect(buyer).buy(listingId, quantityWanted)

      const listing = await marketv2.listings(listingId);

      expect(listing.quantity).to.equal((listingParams.quantityToList as BigNumber).sub(quantityWanted));
    })
  })
});
