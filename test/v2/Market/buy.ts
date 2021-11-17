import { ethers } from "hardhat";
import { expect } from "chai";

// Contract Types
import { Forwarder } from "../../../typechain/Forwarder";
import { AccessNFT } from "../../../typechain/AccessNFT";
import { Coin } from "../../../typechain/Coin";
import { ProtocolControl } from "../../../typechain/ProtocolControl";
import { MarketWithAuction, ListingParametersStruct, ListingStruct } from "../../../typechain/MarketWithAuction";

// Types
import { BigNumber, BigNumberish } from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";
import { getURIs, getAmounts, getBoundedEtherAmount, getAmountBounded } from "../../../utils/tests/params";
import { sendGaslessTx } from "../../../utils/tests/gasless";

describe("Buy: direct listing", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let buyer: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let marketv2: MarketWithAuction;
  let protocolControl: ProtocolControl;
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
  enum ListingType { Direct = 0, Auction = 1 }
  const buyoutPricePerToken: BigNumber = getBoundedEtherAmount();
  const totalQuantityOwned: BigNumberish = rewardSupplies[0]
  const quantityToList = totalQuantityOwned;
  const tokensPerBuyer = totalQuantityOwned - 5;
  const secondsUntilStartTime: number = 0;
  const secondsUntilEndTime: number = 0;

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
    protocolControl = contracts.protocolControl;

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

    // List tokens for sale: direct listing
    listingParams = {
      assetContract: accessNft.address,
      tokenId: rewardId,
      
      secondsUntilStartTime: secondsUntilStartTime,
      secondsUntilEndTime: secondsUntilEndTime,

      quantityToList: quantityToList,
      currencyToAccept: coin.address,

      reservePricePerToken: 0,
      buyoutPricePerToken: buyoutPricePerToken,
      tokensPerBuyer: tokensPerBuyer,

      listingType: ListingType.Direct
    }

    listingId = await marketv2.totalListings();
    await marketv2.connect(creator).createListing(listingParams);
  });

  describe("Revert cases", function() {

    it("Should revert if buyer does not own the required amount of currency", async () => {
      
      const quantityToBuy: BigNumberish = 1;

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")
    })

    it("Should revert if buyer has not approved Market to transfer currency", async () => {
      const quantityToBuy: BigNumberish = 1;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken);

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")      
    })

    it("Should revert if lister does not own the tokens listed", async () => {
      const quantityToBuy: BigNumberish = 1;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken);

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken);

      // Lister transfers away all tokens
      await accessNft.connect(creator).safeTransferFrom(
        creator.address,
        relayer.address,
        rewardId,
        totalQuantityOwned,
        ethers.utils.toUtf8Bytes("")
      )

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: cannot buy tokens from this listing.")
    })

    it("Should revert if lister has removed Market's approval to transfer tokens listed", async () => {
      const quantityToBuy: BigNumberish = 1;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken);

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken);

      // Lister removes Market's approval to transfer tokens
      await accessNft.connect(creator).setApprovalForAll(marketv2.address, false);

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: cannot buy tokens from this listing.")
    })

    it("Should revert if the listing is an auction", async () => {
      const newListingId: BigNumberish = await marketv2.totalListings();
      const newListingParams = listingParams;

      newListingParams.listingType = ListingType.Auction;

      await marketv2.connect(creator).createListing(newListingParams)
  
      const quantityToBuy: BigNumberish = 1;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken);

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken);

      await expect(
        marketv2.connect(buyer).buy(newListingId, quantityToBuy)
      ).to.be.revertedWith("Market: cannot buy tokens from this listing.")      
    })

    it("Should revert if buyer tries to buy 0 tokens", async () => {
      const quantityToBuy: BigNumberish = 0;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToBuy));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToBuy));

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: must buy an appropriate amount of tokens.") 
    })

    it("Should revert if buyer tries to buy more tokens than listed", async () => {
      const quantityToBuy: BigNumberish = totalQuantityOwned + 1;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToBuy));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToBuy));

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: must buy an appropriate amount of tokens.")
    })

    it("Should revert if buyer tries to buy tokens outside the listing's sale window", async () => {
      const newSecondsUntilEnd = 10;

      await marketv2.connect(creator).editListingParametrs(
        listingId,
        listingParams.quantityToList,
        listingParams.reservePricePerToken,
        listingParams.buyoutPricePerToken,
        listingParams.tokensPerBuyer,
        listingParams.currencyToAccept,
        listingParams.secondsUntilStartTime,
        newSecondsUntilEnd
      );

      // Time travel
      for (let i = 0; i < newSecondsUntilEnd; i++) {
        await ethers.provider.send("evm_mine", []);
      }

      const quantityToBuy: BigNumberish = 1;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken);

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken);

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: the sale has either not started or closed.")
    })

    it("Should revert if buyer tries to buy more tokens than permitted per buyer", async () => {
      const quantityToBuy: BigNumberish = 1;
      const totalQty: number = tokensPerBuyer + 1;

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(totalQty));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(totalQty));
      
      await marketv2.connect(buyer).buy(listingId, listingParams.tokensPerBuyer);

      await expect(
        marketv2.connect(buyer).buy(listingId, quantityToBuy)
      ).to.be.revertedWith("Market: must buy an appropriate amount of tokens.")
    })
  })

  describe("Events", function() {

    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })

    it("Should emit NewDirectSale with the sale info", async () => {
      const quantityToBuy: number = 1;

      const eventPromise = new Promise((resolve, reject) => {
        marketv2.on("NewDirectSale", (
          _assetContract,
          _seller,
          _listingId,
          _buyer,
          _quantityBought,
          _listing
        ) => {
          expect(_assetContract).to.equal(accessNft.address)
          expect(_seller).to.equal(creator.address)
          expect(_listingId).to.equal(listingId)
          expect(_buyer).to.equal(buyer.address)
          expect(_quantityBought).to.equal(quantityToBuy)
          expect(_listing.quantity).to.equal(quantityToList - quantityToBuy);

          resolve(null);
        })

        setTimeout(() => {
          reject(new Error("Timeout: NewDirectSale"));
        }, 10000)
      })

      await marketv2.connect(buyer).buy(listingId, quantityToBuy)

      await eventPromise.catch(e => console.error(e));
    })
  })

  describe("Balances", function() {

    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })

    it("Should transfer tokens bought from lister to buyer", async () => {
      const quantityToBuy: number = 1;

      const creatorBalBefore: BigNumberish = await accessNft.balanceOf(creator.address, rewardId);
      const buyerBalBefore: BigNumberish = await accessNft.balanceOf(buyer.address, rewardId);

      await marketv2.connect(buyer).buy(listingId, quantityToBuy)

      const creatorBalAfter: BigNumberish = await accessNft.balanceOf(creator.address, rewardId);
      const buyerBalAfter: BigNumberish = await accessNft.balanceOf(buyer.address, rewardId);

      expect(creatorBalAfter).to.equal(creatorBalBefore.sub(quantityToBuy))
      expect(buyerBalAfter).to.equal(buyerBalBefore.add(quantityToBuy))
    })

    it("Should transfer currency from buyer to lister", async () => {

      // No fees or royalty set up.

      const quantityToBuy: number = 1;
      const totalPrice: BigNumberish = buyoutPricePerToken.mul(quantityToBuy)

      const creatorBalBefore: BigNumberish = await coin.balanceOf(creator.address);
      const buyerBalBefore: BigNumberish = await coin.balanceOf(buyer.address);

      await marketv2.connect(buyer).buy(listingId, quantityToBuy)

      const creatorBalAfter: BigNumberish = await coin.balanceOf(creator.address);
      const buyerBalAfter: BigNumberish = await coin.balanceOf(buyer.address);

      expect(creatorBalAfter).to.equal(creatorBalBefore.add(totalPrice))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(totalPrice))
    })

    it("Should distribute sale value to the relevant stake holders", async () => {
      const royaltyTreasury: string = await protocolControl.getRoyaltyTreasury(marketv2.address);

      // Set a market fee
      await marketv2.connect(protocolAdmin).setMarketFeeBps(500) // 5%
      // Set royalty on listed tokens
      await accessNft.connect(protocolAdmin).setRoyaltyBps(500); // 5%

      const quantityToBuy: number = 1;
      const totalPrice: BigNumber = buyoutPricePerToken.mul(quantityToBuy)
      const marketCut: BigNumber = totalPrice.mul(500).div(10000);
      const tokenRoyalty: BigNumber = totalPrice.mul(500).div(10000);

      const royaltyTreasuryBefore: BigNumberish = await coin.balanceOf(royaltyTreasury);
      const creatorBalBefore: BigNumberish = await coin.balanceOf(creator.address);
      const buyerBalBefore: BigNumberish = await coin.balanceOf(buyer.address);

      await marketv2.connect(buyer).buy(listingId, quantityToBuy)

      const royaltyTreasuryAfter: BigNumberish = await coin.balanceOf(royaltyTreasury);
      const creatorBalAfter: BigNumberish = await coin.balanceOf(creator.address);
      const buyerBalAfter: BigNumberish = await coin.balanceOf(buyer.address);

      expect(royaltyTreasuryAfter).to.equal(royaltyTreasuryBefore.add(marketCut.add(tokenRoyalty)))
      expect(creatorBalAfter).to.equal(creatorBalBefore.add(totalPrice.sub(marketCut.add(tokenRoyalty))))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(totalPrice))
      
    })
  })

  describe("Contract state", function() {

    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })

    it("Should decrease the quantity available in the listing", async () => {
      const quantityToBuy: number = 1;

      await marketv2.connect(buyer).buy(listingId, quantityToBuy)

      const listing = await marketv2.listings(listingId);

      expect(listing.quantity).to.equal(quantityToList - quantityToBuy);
    })

    it("Should update the tokens already bought from the listing by the buyer", async () => {
      const quantityToBuy: number = 1;

      const boughttBefore: BigNumber = await marketv2.boughtFromListing(listingId, buyer.address);
    
      await marketv2.connect(buyer).buy(listingId, quantityToBuy)

      const boughtAfter: BigNumber = await marketv2.boughtFromListing(listingId, buyer.address);

      expect(boughtAfter).to.equal(boughttBefore.add(quantityToBuy))
    })
  })
});
