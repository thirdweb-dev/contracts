// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts } from "../utils/tests/getContracts";
const { signMetaTxRequest } = require("../../utils/meta-tx/signer");

describe("List token for sale", function () {
  // Signers
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: Contract;
  let market: Contract;
  let accessNft: Contract;
  let coin: Contract;
  let forwarder: Contract;

  // Reward parameterrs
  const packURI: string = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
  const rewardURIs: string[] = [
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
  ];
  const accessURIs = rewardURIs;
  const rewardSupplies: number[] = [5, 25, 60];
  const openStartAndEnd: number = 0;
  const rewardsPerOpen: number = 1;

  // Expected results
  let expectedPackId: number;

  // Market params
  const pricePerToken = ethers.utils.parseEther("1");
  const amountToList = 5;

  beforeEach(async () => {
    // Get signers
    const networkName: string = "mumbai";
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [creator, relayer] = signers;

    // Get contracts
    [pack, accessNft, forwarder, market, coin] = await getContracts(creator, networkName, [
      "Pack",
      "AccessNFT",
      "Forwarder",
      "Market",
      "Coin",
    ]);

    // Get expected packId
    expectedPackId = await pack.nextTokenId();

    // Create access packs
    await accessNft
      .connect(creator)
      .createAccessPack(
        pack.address,
        rewardURIs,
        accessURIs,
        rewardSupplies,
        packURI,
        openStartAndEnd,
        openStartAndEnd,
        rewardsPerOpen,
      );

    // Approve market to transfer tokens
    await pack.connect(creator).setApprovalForAll(market.address, true);
  });

  describe("Revert")
  describe("Events")
  describe("Balances")
  describe("Contract state")
});
