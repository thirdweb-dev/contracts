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

describe("Offer: direct listing", function () {
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
  const buyoutPricePerToken: BigNumber = ethers.utils.parseEther("2");
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
      
      const quantityWanted: BigNumberish = 1;
      const offerAmount = ethers.utils.parseEther("1");

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")
    })

    it("Should revert if buyer has not approved Market to transfer currency", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = ethers.utils.parseEther("1");

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken);

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
      ).to.be.revertedWith("Market: must own and approve Market to transfer currency.")
    })
  })

  describe("Events", function() {

    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })

    it("Should emit NewOffer with the relevant offer info", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = ethers.utils.parseEther("1");

      const eventPromise = new Promise((resolve, reject) => {
        marketv2.on("NewOffer", (
          _listingId,
          _offeror,
          _offer,
          _listing
        ) => {

          expect(_listingId).to.equal(listingId)
          expect(_offeror).to.equal(buyer.address)
          
          expect(_offer.listingId).to.equal(listingId)
          expect(_offer.offeror).to.equal(buyer.address)
          expect(_offer.quantityWanted).to.equal(quantityWanted)
          expect(_offer.offerAmount).to.equal(offerAmount);

          expect(_listing.listingId).to.equal(listingId);
          expect(_listing.tokenOwner).to.equal(creator.address);
          expect(_listing.assetContract).to.equal(accessNft.address);
          expect(_listing.tokenId).to.equal(rewardId);
          
          expect(_listing.endTime).to.be.gt(_listing.startTime);

          expect(_listing.quantity).to.equal(quantityToList)
          expect(_listing.currency).to.equal(coin.address);
          expect(_listing.reservePricePerToken).to.equal(0);
          expect(_listing.buyoutPricePerToken).to.equal(buyoutPricePerToken);
          expect(_listing.tokensPerBuyer).to.equal(tokensPerBuyer);
          expect(_listing.tokenType).to.equal(0) // 0 == ERC1155
          expect(_listing.listingType).to.equal(ListingType.Direct);

          resolve(null)
        })

        setTimeout(() => {
          reject("Timeout: NewOffer")
        }, 10000)
      })

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
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

    it("Should not affect token balances when an offer is made", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = ethers.utils.parseEther("1");

      const creatorBalBefore: BigNumberish = await accessNft.balanceOf(creator.address, rewardId);
      const buyerBalBefore: BigNumberish = await accessNft.balanceOf(buyer.address, rewardId);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)

      const creatorBalAfter: BigNumberish = await accessNft.balanceOf(creator.address, rewardId);
      const buyerBalAfter: BigNumberish = await accessNft.balanceOf(buyer.address, rewardId);

      expect(creatorBalAfter).to.equal(creatorBalBefore)
      expect(buyerBalAfter).to.equal(buyerBalBefore)
    })
  })

  describe("Contract state", function() {

    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })
    
    it("Should store the offer info", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = ethers.utils.parseEther("1");
      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
      
      const _offer = await marketv2.offers(listingId, buyer.address);

      expect(_offer.listingId).to.equal(listingId)
      expect(_offer.offeror).to.equal(buyer.address)
      expect(_offer.quantityWanted).to.equal(quantityWanted)
      expect(_offer.offerAmount).to.equal(offerAmount);
      
    })
  })
});
