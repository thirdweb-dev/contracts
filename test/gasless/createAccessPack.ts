// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts } from "../../utils/tests/params";
const { signMetaTxRequest } = require("../../utils/meta-tx/signer");

describe("Create a pack with rewards in a single tx", function () {
  // Signers
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let pack: Contract;
  let accessNft: Contract;
  let forwarder: Contract;

  // Reward parameterrs
  const [packURI]: string[] = getURIs(1);
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getAmounts(rewardURIs.length);

  const openStartAndEnd: number = 0;
  const rewardsPerOpen: number = 1;

  beforeEach(async () => {
    // Get signers
    const networkName: string = "mumbai";
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [creator, relayer] = signers;

    // Get contracts
    let contracts = await getContracts(creator, networkName);
    pack = contracts.pack;
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;
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
