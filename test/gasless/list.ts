// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts } from "../../utils/tests/getContracts";
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

  describe("Should create access packs", function () {
    it("Regular transaction", async () => {
      // Get pack balance before pack creation.
      const packBalanceBefore = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceBefore).to.equal(rewardSupplies.reduce((a, b) => a + b));

      // List on market
      await market
        .connect(creator)
        .list(
          pack.address,
          expectedPackId,
          coin.address,
          pricePerToken,
          amountToList,
          openStartAndEnd,
          openStartAndEnd,
        );

      // Get pack balance after pack creation.
      const packBalanceAfer = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceAfer).to.equal(rewardSupplies.reduce((a, b) => a + b) - amountToList);
    });

    it("Meta-Tx", async () => {
      // Get pack balance before pack creation.
      const packBalanceBefore = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceBefore).to.equal(rewardSupplies.reduce((a, b) => a + b));

      // Meta tx setup
      const from = creator.address;
      const to = market.address;

      const data = market.interface.encodeFunctionData("list", [
        pack.address,
        expectedPackId,
        coin.address,
        pricePerToken,
        amountToList,
        openStartAndEnd,
        openStartAndEnd,
      ]);

      // Execute meta tx
      const { request, signature } = await signMetaTxRequest(creator.provider, forwarder, { from, to, data });
      await forwarder.connect(relayer).execute(request, signature);

      // Get pack balance after pack creation.
      const packBalanceAfer = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceAfer).to.equal(rewardSupplies.reduce((a, b) => a + b) - amountToList);
    });
  });
});
