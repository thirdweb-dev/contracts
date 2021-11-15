import { ethers } from "hardhat";
import { expect } from "chai";

// Contract Types
import { Forwarder } from "../../../typechain/Forwarder";
import { AccessNFT } from "../../../typechain/AccessNFT";
import { MarketWithAuction, ListingParametersStruct } from "../../../typechain/MarketWithAuction";
import { Coin } from "../../../typechain/Coin";

// Types
import { BigNumber } from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";
import { getURIs, getAmounts, getBoundedEtherAmount, getAmountBounded } from "../../../utils/tests/params";
import { sendGaslessTx } from "../../../utils/tests/gasless";

describe("List token for sale: Direct Listing", function () {
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
  let listingParams: ListingParametersStruct;
  enum ListingType { Direct = 0, Auction = 1 }
  const price: BigNumber = getBoundedEtherAmount();
  const amountOfTokenToList = getAmountBounded(rewardSupplies[0]);
  const tokensPerBuyer = getAmountBounded(parseInt(amountOfTokenToList.toString()));
  const openStartAndEnd: number = 0;

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

    listingParams = {
      assetContract: accessNft.address,
      tokenId: rewardId,
      
      secondsUntilStartTime: openStartAndEnd,
      secondsUntilEndTime: openStartAndEnd,

      quantityToList: amountOfTokenToList,
      currencyToAccept: coin.address,

      reservePricePerToken: 0,
      buyoutPricePerToken: price,
      tokensPerBuyer: tokensPerBuyer,

      listingType: ListingType.Direct
    }
  });

  describe("Revert cases", function() {
    it("Should revert if listing zero quantity.", async () => {

      const incorrectParams = listingParams;
      incorrectParams.quantityToList = 0;

      await expect(
        marketv2.connect(creator).createListing(incorrectParams)
      ).to.be.revertedWith("Market: must own and approve to transfer tokens.")
    })

    it("Should revert if lister has insufficient token balance", async () => {
      await expect(
        marketv2.connect(relayer).createListing(listingParams)
      ).to.be.revertedWith("Market: must own and approve to transfer tokens.")
    })

    it("Should revert if market doesn't have lister's approval to transfer tokens", async () => {
      await expect(
        marketv2.connect(creator).createListing(listingParams)
      ).to.be.revertedWith("Market: must own and approve to transfer tokens.")
    })
  })
});
