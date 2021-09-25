// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts } from "../utils/tests/getContracts";
const { signMetaTxRequest } = require("../utils/meta-tx/signer");

describe("Create a pack with rewards in a single tx", function () {
  // Signers
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: Contract;
  let accessNft: Contract;
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

  beforeEach(async () => {
    // Get signers
    const networkName: string = "mumbai";
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [creator, relayer] = signers;

    // Get contracts
    [pack, accessNft, forwarder] = await getContracts(creator, networkName, ["Pack", "AccessNFT", "Forwarder"]);
  });

  describe("Should create access packs", function () {
    it("Regular transaction", async () => {
      // Get expected pack tokenId
      const expectedPackId: number = await pack.nextTokenId();

      // Get pack balance before pack creation.
      const packBalanceBefore = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceBefore).to.equal(0);

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

      // Get pack balance after pack creation.
      const packBalanceAfer = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceAfer).to.equal(rewardSupplies.reduce((a, b) => a + b));
    });

    it("Meta-Tx", async () => {
      // Get expected pack tokenId
      const expectedPackId: number = await pack.nextTokenId();

      // Get pack balance before pack creation.
      const packBalanceBefore = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceBefore).to.equal(0);

      // Meta tx setup
      const from = creator.address;
      const to = accessNft.address;

      const data = accessNft.interface.encodeFunctionData("createAccessPack", [
        pack.address,
        rewardURIs,
        accessURIs,
        rewardSupplies,
        packURI,
        openStartAndEnd,
        openStartAndEnd,
        rewardsPerOpen,
      ]);

      // Execute meta tx
      const { request, signature } = await signMetaTxRequest(creator.provider, forwarder, { from, to, data });
      await forwarder.connect(relayer).execute(request, signature);

      // Get pack balance after pack creation.
      const packBalanceAfer = await pack.balanceOf(creator.address, expectedPackId);
      expect(packBalanceAfer).to.equal(rewardSupplies.reduce((a, b) => a + b));
    });
  });
});