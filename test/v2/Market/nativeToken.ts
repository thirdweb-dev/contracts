import { ethers } from "hardhat";
import { expect } from "chai";

// Contract Types
import { Forwarder } from "../../../typechain/Forwarder";
import { AccessNFT } from "../../../typechain/AccessNFT";
import { Coin } from "../../../typechain/Coin";
import { MarketWithAuction, ListingParametersStruct, ListingStruct } from "../../../typechain/MarketWithAuction";

// Types
import { BigNumberish, BigNumber, Signer } from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";
import { getURIs, getAmounts, getBoundedEtherAmount, getAmountBounded } from "../../../utils/tests/params";
import { sendGaslessTx } from "../../../utils/tests/gasless";

describe("Bid: Auction Listing", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let buyer: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let marketv2: MarketWithAuction;
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
  const buyoutPricePerToken: BigNumber = ethers.utils.parseEther("0.2");
  const reservePricePerToken: BigNumberish = ethers.utils.parseEther("0.1");
  const totalQuantityOwned: BigNumberish = rewardSupplies[0]
  const quantityToList = 1;
  const tokensPerBuyer = 1;
  const secondsUntilStartTime: number = 0;
  const secondsUntilEndTime: number = 100;
  const currencyAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

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

    listingParams = {
      assetContract: accessNft.address,
      tokenId: rewardId,
      
      secondsUntilStartTime: secondsUntilStartTime,
      secondsUntilEndTime: secondsUntilEndTime,

      quantityToList: quantityToList,
      currencyToAccept: currencyAddress,

      reservePricePerToken: reservePricePerToken,
      buyoutPricePerToken: buyoutPricePerToken,
      tokensPerBuyer: tokensPerBuyer,

      listingType: ListingType.Auction
    }

    listingId = await marketv2.totalListings();
    await marketv2.connect(creator).createListing(listingParams);
  });
  
  describe("Revert cases", async () => {

    it("Should revert if bid is less than reserve price", async () => {
      const quantityWanted: BigNumberish = 1; // shouldn't matter
      const invalidOfferAmount = reservePricePerToken.sub(
        ethers.utils.parseEther("0.001")
      ).mul(quantityWanted);

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, invalidOfferAmount)
      ).to.be.revertedWith("Market: must offer at least reserve price.")
    })

    it("Should revert if bid is made outside the auction window", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      // Time travel
      // for (let i = 0; i < secondsUntilEndTime; i++) {
        await ethers.provider.send("evm_increaseTime", [secondsUntilEndTime])
      // }

      await ethers.provider.send("evm_mine", []);

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
      ).to.be.revertedWith("Market: can only make offers in listing duration.")
    })

    it("Should revert if buyer does not own the required amount of currency", async () => {
      
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
      ).to.be.reverted;
    })

    it("Should revert if buyer has not approved Market to transfer currency", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken);

      await expect(
        marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount)
      ).to.be.reverted;
    })
  })

  describe("Events", function() {

    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })

    it("Should emit NewOffer with relevant offer info", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

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
          expect(_offer.quantityWanted).to.equal(quantityToList)
          expect(_offer.offerAmount).to.equal(offerAmount);

          expect(_listing.listingId).to.equal(listingId);
          expect(_listing.tokenOwner).to.equal(creator.address);
          expect(_listing.assetContract).to.equal(accessNft.address);
          expect(_listing.tokenId).to.equal(rewardId);
          
          expect(_listing.endTime).to.be.gt(_listing.startTime);

          expect(_listing.quantity).to.equal(quantityToList)
          expect(_listing.currency).to.equal(currencyAddress);
          expect(_listing.reservePricePerToken).to.equal(reservePricePerToken);
          expect(_listing.buyoutPricePerToken).to.equal(buyoutPricePerToken);
          expect(_listing.tokensPerBuyer).to.equal(tokensPerBuyer);
          expect(_listing.tokenType).to.equal(0) // 0 == ERC1155
          expect(_listing.listingType).to.equal(ListingType.Auction);

          resolve(null)
        })

        setTimeout(() => {
          reject("Timeout: NewOffer")
        }, 10000)
      })

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount })
      await eventPromise.catch(e => console.error(e));
    })

    it("Should emit NewBid if the incoming bid is the new highest bid, but below buyout price", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      const eventPromise = new Promise((resolve, reject) => {
        
        marketv2.on("NewBid", (
          _listingId,
          _bidder,
          _bid,
          _listing
        ) => {
          expect(_listingId).to.equal(listingId)
          expect(_bidder).to.equal(buyer.address)
          
          expect(_bid.listingId).to.equal(listingId)
          expect(_bid.offeror).to.equal(buyer.address)
          expect(_bid.quantityWanted).to.equal(quantityToList)
          expect(_bid.offerAmount).to.equal(offerAmount);

          expect(_listing.listingId).to.equal(listingId);
          expect(_listing.tokenOwner).to.equal(creator.address);
          expect(_listing.assetContract).to.equal(accessNft.address);
          expect(_listing.tokenId).to.equal(rewardId);
          
          expect(_listing.endTime).to.be.gt(_listing.startTime);

          expect(_listing.quantity).to.equal(quantityToList)
          expect(_listing.currency).to.equal(currencyAddress);
          expect(_listing.reservePricePerToken).to.equal(reservePricePerToken);
          expect(_listing.buyoutPricePerToken).to.equal(buyoutPricePerToken);
          expect(_listing.tokensPerBuyer).to.equal(tokensPerBuyer);
          expect(_listing.tokenType).to.equal(0) // 0 == ERC1155
          expect(_listing.listingType).to.equal(ListingType.Auction);

          resolve(null)
        })

        setTimeout(() => {
          reject("Timeout: NewBid")
        }, 10000)        
      })

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount })
      await eventPromise.catch(e => console.error(e));
    })

    // it("Should not emit NewBid if incoming bid is not the new highest bid, and is below buyout price", async () => {

    //   // Mint currency to second buyer
    //   await coin.connect(protocolAdmin).mint(relayer.address, buyoutPricePerToken.mul(quantityToList));

    //   // Approve Market to transfer currency
    //   await coin.connect(relayer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));

    //   const quantityWanted: BigNumberish = 1;
    //   const highOfferAmount = (reservePricePerToken.add(
    //     ethers.utils.parseEther("0.1")
    //   )).mul(quantityToList);

    //   const endTime = (await marketv2.listings(listingId)).endTime
    //   await ethers.provider.send("evm_setNextBlockTimestamp", [endTime.sub(10).toNumber()]);
    //   await ethers.provider.send("evm_mine", []);

    //   await marketv2.connect(buyer).offer(listingId, quantityWanted, highOfferAmount, { value: highOfferAmount })

    //   const lowOfferAmount = reservePricePerToken.mul(quantityToList);

    //   const txReceipt = await marketv2.connect(relayer).offer(listingId, quantityWanted, lowOfferAmount, { value: lowOfferAmount })
    //     .then(tx => tx.wait());
      
    //   const newBidTopic = marketv2.interface.getEventTopic("NewBid");
    //   const newBidDNE = !(txReceipt.logs.find(x => x.topics.indexOf(newBidTopic) >= 0));

    //   expect(newBidDNE).to.equal(true);
    // })
    
    it("Should emit AuctionClosed if bid is greater or equal to buyout price", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = buyoutPricePerToken.mul(quantityToList);

      const eventPromise = new Promise((resolve, reject) => {
        marketv2.on("AuctionClosed", (
          _listingId,
          _closer,
          _auctionCreator,
          _winningBidder,
          _winningBid,
          _listing
        ) => {

          expect(_listingId).to.equal(listingId)
          expect(_closer).to.equal(buyer.address)
          expect(_auctionCreator).to.equal(creator.address)
          expect(_winningBidder).to.equal(buyer.address)
          
          expect(_winningBid.listingId).to.equal(listingId)
          expect(_winningBid.offeror).to.equal(buyer.address)
          expect(_winningBid.quantityWanted).to.equal(quantityToList)
          expect(_winningBid.offerAmount).to.equal(offerAmount);

          expect(_listing.listingId).to.equal(listingId);
          expect(_listing.tokenOwner).to.equal(creator.address);
          expect(_listing.assetContract).to.equal(accessNft.address);
          expect(_listing.tokenId).to.equal(rewardId);
          
          expect(_listing.endTime).to.be.gt(_listing.startTime);

          expect(_listing.quantity).to.equal(quantityToList)
          expect(_listing.currency).to.equal(currencyAddress);
          expect(_listing.reservePricePerToken).to.equal(reservePricePerToken);
          expect(_listing.buyoutPricePerToken).to.equal(buyoutPricePerToken);
          expect(_listing.tokensPerBuyer).to.equal(tokensPerBuyer);
          expect(_listing.tokenType).to.equal(0) // 0 == ERC1155
          expect(_listing.listingType).to.equal(ListingType.Auction);

          resolve(null)
        })

        setTimeout(() => {
          reject("Timeout: AuctionClosed")
        }, 10000)   
      })

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount })
      await eventPromise.catch(e => console.error(e));
    })
  })

  describe("Balances", async () => {

    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })
    
    it("Should escrow currency in Market if bid is valid", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      const buyerBalBefore: BigNumber = await ethers.provider.getBalance(buyer.address)
      const marketBalBefore: BigNumber = await ethers.provider.getBalance(marketv2.address);

      const gasPrice = ethers.utils.parseUnits("1", "gwei");
      const tx = await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount, gasPrice })
      const gasUsed = (await tx.wait()).gasUsed;
      const gasPaid = gasPrice.mul(gasUsed);

      const buyerBalAfter: BigNumber = await ethers.provider.getBalance(buyer.address)
      const marketBalAfter: BigNumber = await ethers.provider.getBalance(marketv2.address);

      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(offerAmount.add(gasPaid)))
      expect(marketBalAfter).to.equal(marketBalBefore.add(offerAmount));
    })

    it("Should payout the previous bidder, if new bid is higher than the previous bid", async () => {
      const quantityWanted: BigNumberish = 1;
      const highOfferAmount = (reservePricePerToken.mul(quantityToList)).add(
        ethers.utils.parseEther("0.1")
      );
      const lowOfferAmount = reservePricePerToken.mul(quantityToList);

      // Mint currency to prevBuyer
      await coin.connect(protocolAdmin).mint(relayer.address, buyoutPricePerToken.mul(quantityToList));
      // Approve Market to transfer currency
      await coin.connect(relayer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
      
      const prevBuyerBalBefore: BigNumber = await ethers.provider.getBalance(relayer.address)
      const buyerBalBefore: BigNumber = await ethers.provider.getBalance(buyer.address)
      const marketBalBefore: BigNumber = await ethers.provider.getBalance(marketv2.address);

      const gasPrice = ethers.utils.parseUnits("1", "gwei");
      
      const tx1 = await marketv2.connect(relayer).offer(listingId, quantityWanted, lowOfferAmount, { value: lowOfferAmount, gasPrice });
      const tx2 = await marketv2.connect(buyer).offer(listingId, quantityWanted, highOfferAmount, { value: highOfferAmount, gasPrice });

      const gasUsed1 = (await tx1.wait()).gasUsed;
      const gasUsed2 = (await tx2.wait()).gasUsed;
      const gasPaid1 = gasPrice.mul(gasUsed1);
      const gasPaid2 = gasPrice.mul(gasUsed2);
      
      const prevBuyerBalAfter: BigNumber = await ethers.provider.getBalance(relayer.address)
      const buyerBalAfter: BigNumber = await ethers.provider.getBalance(buyer.address)
      const marketBalAfter: BigNumber = await ethers.provider.getBalance(marketv2.address);
      
      expect(prevBuyerBalAfter).to.equal(prevBuyerBalBefore.sub(gasPaid1))
      expect(buyerBalAfter).to.equal(buyerBalBefore.sub(highOfferAmount.add(gasPaid2)))
      expect(marketBalAfter).to.equal(marketBalBefore.add(highOfferAmount));
    });

    it("Should transfer auctioned tokens to bidder if bid is at buyout price.", async () => {
      const quantityWanted: BigNumberish = 1;
      const auctionQuantity: BigNumber =  (await marketv2.listings(listingId)).quantity;
      const offerAmount = buyoutPricePerToken.mul(quantityToList);

      const buyerBalBefore: BigNumber = await accessNft.balanceOf(buyer.address, rewardId)
      const marketBalBefore: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount })

      const buyerBalAfter: BigNumber = await accessNft.balanceOf(buyer.address, rewardId)
      const marketBalAfter: BigNumber = await accessNft.balanceOf(marketv2.address, rewardId);

      expect(buyerBalAfter).to.equal(buyerBalBefore.add(auctionQuantity))
      expect(marketBalAfter).to.equal(marketBalBefore.sub(auctionQuantity));
    })
  })

  describe("Contract state", function() {
    beforeEach(async () => {
      // Mint currency to buyer
      await coin.connect(protocolAdmin).mint(buyer.address, buyoutPricePerToken.mul(quantityToList));

      // Approve Market to transfer currency
      await coin.connect(buyer).approve(marketv2.address, buyoutPricePerToken.mul(quantityToList));
    })

    it("Should store a valid offer regardless", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount })

      const _offer = await marketv2.offers(listingId, buyer.address);

      expect(_offer.listingId).to.equal(listingId)
      expect(_offer.offeror).to.equal(buyer.address)
      expect(_offer.quantityWanted).to.equal(quantityToList)
      expect(_offer.offerAmount).to.equal(offerAmount);
    })

    it("Should store the offer as the winning bid if it is the new highest bid", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount })

      const _winningBid = await marketv2.winningBid(listingId);

      expect(_winningBid.listingId).to.equal(listingId)
      expect(_winningBid.offeror).to.equal(buyer.address)
      expect(_winningBid.quantityWanted).to.equal(quantityToList)
      expect(_winningBid.offerAmount).to.equal(offerAmount);
    })

    it("Should increment the listing's end time if the bid is within the time buffer", async () => {
      
      const timeBuffer: BigNumber = await marketv2.timeBuffer();
      const endTimeBefore: BigNumber = (await marketv2.listings(listingId)).endTime;
      
      const quantityWanted: BigNumberish = 1;
      const offerAmount = reservePricePerToken.mul(quantityToList);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount });

      const endTimeAfter: BigNumber = (await marketv2.listings(listingId)).endTime;

      expect(endTimeAfter).to.equal(endTimeBefore.add(timeBuffer));
    })

    it("Should close the auction by updating the listing's end time, if the bid is buyout price", async () => {
      const quantityWanted: BigNumberish = 1;
      const offerAmount = buyoutPricePerToken.mul(quantityToList);

      await marketv2.connect(buyer).offer(listingId, quantityWanted, offerAmount, { value: offerAmount });

      const timeStamp = await (await ethers.provider.getBlock("latest")).timestamp;
      const endTimeAfter: BigNumber = (await marketv2.listings(listingId)).endTime;

      expect(timeStamp).to.equal(endTimeAfter);
    })
  })
});