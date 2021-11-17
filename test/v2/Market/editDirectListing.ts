import { ethers } from "hardhat";
import { expect } from "chai";

// Contract Types
import { Forwarder } from "../../../typechain/Forwarder";
import { AccessNFT } from "../../../typechain/AccessNFT";
import { Coin } from "../../../typechain/Coin";
import { MarketWithAuction, ListingParametersStruct, ListingStruct } from "../../../typechain/MarketWithAuction";

// Types
import { BigNumber, BigNumberish } from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";
import { getURIs, getAmounts, getBoundedEtherAmount, getAmountBounded } from "../../../utils/tests/params";
import { sendGaslessTx } from "../../../utils/tests/gasless";

describe("Edit listing: direct listing", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
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
  const buyoutPricePerToken: BigNumber = getBoundedEtherAmount();
  const totalQuantityOwned: BigNumberish = rewardSupplies[0]
  const quantityToList = getAmountBounded(totalQuantityOwned);
  const tokensPerBuyer = getAmountBounded(parseInt(quantityToList.toString()));
  const secondsUntilStartTime: number = 0;
  const secondsUntilEndTime: number = 0;

  let listingParams: ListingParametersStruct;
  let listingId: BigNumberish;

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, creator, relayer] = signers;
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
    it("Should revert if lister edits quantity to an amount they don't own or have approved for transfer", async () => {
      const invalidNewQuantity = totalQuantityOwned + 1;

      await expect(
        marketv2.connect(creator).editListingParametrs(
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
      const newTokensPerBuyer: BigNumberish = 1;
      const newSecondsUntilStartTime: BigNumberish = 1;
      const newSecondsUntilEndTime: BigNumberish = 6000;

      const eventPromise = new Promise((resolve, reject) => {
        marketv2.on("ListingUpdate", (_listingCreator, _listingId, _listing) => {
          expect(_listingCreator).to.equal(creator.address)
          expect(_listingId).to.equal(listingId)

          expect(_listing.listingId).to.equal(listingId);
          expect(_listing.tokenOwner).to.equal(creator.address);
          expect(_listing.assetContract).to.equal(accessNft.address);
          expect(_listing.tokenId).to.equal(rewardId);
          
          expect(_listing.endTime.sub(_listing.startTime))
            .to.equal(newSecondsUntilEndTime - newSecondsUntilStartTime);

          expect(_listing.quantity).to.equal(quantityToList)
          expect(_listing.currency).to.equal(coin.address);
          expect(_listing.reservePricePerToken).to.equal(0);
          expect(_listing.buyoutPricePerToken).to.equal(buyoutPricePerToken);
          expect(_listing.tokensPerBuyer).to.equal(newTokensPerBuyer);
          expect(_listing.tokenType).to.equal(0) // 0 == ERC1155
          expect(_listing.listingType).to.equal(ListingType.Direct);

          resolve(null)
        })

        setTimeout(() => {
          reject(new Error("Timeout: NewListing"))
        }, 10000);
      })

      await marketv2.connect(creator).editListingParametrs(
        listingId,
        quantityToList,
        listingParams.reservePricePerToken,
        listingParams.buyoutPricePerToken,
        newTokensPerBuyer,
        listingParams.currencyToAccept,
        newSecondsUntilStartTime,
        newSecondsUntilEndTime
      )

      await eventPromise.catch(e => console.error(e));
    })
  })

  describe("Balances", function() {
    it("Should not affect token balance on editing listing quantity", async () => {
      const balBefore: BigNumberish = await accessNft.balanceOf(creator.address, rewardId)
      await marketv2.connect(creator).editListingParametrs(
        listingId,
        listingParams.quantityToList,
        listingParams.reservePricePerToken,
        listingParams.buyoutPricePerToken,
        listingParams.tokensPerBuyer,
        listingParams.currencyToAccept,
        listingParams.secondsUntilStartTime,
        listingParams.secondsUntilEndTime
      )
      const balAfter: BigNumberish = await accessNft.balanceOf(creator.address, rewardId)

      expect(balAfter).to.equal(balBefore);
    })
  })

  describe("Contract state", function() {
    it("Should store the edited listing state", async () => {
      const newTokensPerBuyer: BigNumberish = 1;
      const newSecondsUntilStartTime: BigNumberish = 1;
      const newSecondsUntilEndTime: BigNumberish = 6000;

      await marketv2.connect(creator).editListingParametrs(
        listingId,
        quantityToList,
        listingParams.reservePricePerToken,
        listingParams.buyoutPricePerToken,
        newTokensPerBuyer,
        listingParams.currencyToAccept,
        newSecondsUntilStartTime,
        newSecondsUntilEndTime
      )

      const _listing: ListingStruct = await marketv2.listings(listingId);

      expect(_listing.listingId).to.equal(listingId);
      expect(_listing.tokenOwner).to.equal(creator.address);
      expect(_listing.assetContract).to.equal(accessNft.address);
      expect(_listing.tokenId).to.equal(rewardId);
          
      expect((_listing.endTime as BigNumber).sub(_listing.startTime))
        .to.equal(newSecondsUntilEndTime - newSecondsUntilStartTime);

      expect(_listing.quantity).to.equal(quantityToList)
      expect(_listing.currency).to.equal(coin.address);
      expect(_listing.reservePricePerToken).to.equal(0);
      expect(_listing.buyoutPricePerToken).to.equal(buyoutPricePerToken);
      expect(_listing.tokensPerBuyer).to.equal(newTokensPerBuyer);
      expect(_listing.tokenType).to.equal(0) // 0 == ERC1155
      expect(_listing.listingType).to.equal(ListingType.Direct);
    })
  })
});
