// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts } from "../utils/tests/getContracts";
const { signMetaTxRequest } = require("../../utils/meta-tx/signer");

describe("Redeem access", function () {
  // Signers
  let creator: SignerWithAddress;
  let fan: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: Contract;
  let accessNft: Contract;
  let forwarder: Contract;

  // Reward parameterrs
  const rewardURIs: string[] = [
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
  ];
  const accessURIs = rewardURIs;
  const rewardSupplies: number[] = [5, 25, 60];

  // Expected results
  const expectedRewardIds: number[] = [1, 3, 5];
  const expectedAccessIds: number[] = [0, 2, 4];
  const accessIndex: number = 0;

  beforeEach(async () => {
    // Get signers
    const networkName: string = "mumbai";
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [creator, fan, relayer] = signers;

    // Get contracts
    [pack, accessNft, forwarder] = await getContracts(creator, networkName, ["Pack", "AccessNFT", "Forwarder"]);

    // Create access NFTs
    await accessNft.connect(creator).createAccessNfts(rewardURIs, accessURIs, rewardSupplies);

    // Send access NFTs to fan
    await accessNft
      .connect(creator)
      .safeTransferFrom(creator.address, fan.address, expectedRewardIds[accessIndex], 1, ethers.utils.toUtf8Bytes(""));
  });

  describe("Revert");
  describe("Events");
  describe("Balances");
  describe("Contract state");
});
