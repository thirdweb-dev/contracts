import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC20 } from "typechain/LazyMintERC20";
import { Coin } from "typechain/Coin";

// Types
import { BigNumber, BytesLike } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";
import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";

use(solidity);

describe("Test: claim lazy minted tokens with erc20 tokens", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let claimer: SignerWithAddress;

  // Contracts
  let lazyMintERC20: LazyMintERC20;
  let erc20Token: Coin;

  // Lazy minting params
  const amountToLazyMint: BigNumber = BigNumber.from(10_000);
  const baseURI: string = "ipfs://baseURI/";

  // Setting mint conditions default params
  let mintConditions: any[];

  // Claim params
  let proof: BytesLike[];
  let quantityToClaim: BigNumber;
  let totalPrice: BigNumber;

  // Test params
  let targetMintConditionIndex: BigNumber;
  let royaltyTreasury: string;

  // Helper functions

  const timeTravelToMintCondition = async (_conditionIndex: BigNumber) => {
    // Time travel
    const travelTo: string = (await lazyMintERC20.getClaimConditionAtIndex(_conditionIndex)).startTimestamp.toString();
    await ethers.provider.send("evm_mine", [parseInt(travelTo)]);
  };

  const mintERC20To = async (to: SignerWithAddress, amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(protocolAdmin).mint(to.address, amount);

    // Approve Market to transfer currency
    await erc20Token.connect(to).approve(lazyMintERC20.address, amount);
  };

  before(async () => {
    [protocolProvider, protocolAdmin, claimer] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    lazyMintERC20 = contracts.lazyMintERC20;
    erc20Token = contracts.coin;
    royaltyTreasury = contracts.protocolControl.address;

    // Set claim params
    quantityToClaim = BigNumber.from(10);
    totalPrice = quantityToClaim.mul(ethers.utils.parseEther("0.1"));

    // Generate a merkle root for whitelisting
    const leaves = [[claimer.address, quantityToClaim]].map(x =>
      ethers.utils.solidityKeccak256(["address", "uint256"], x),
    );
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const whitelist = tree.getRoot();
    proof = tree.getHexProof(
      ethers.utils.solidityKeccak256(["address", "uint256"], [claimer.address, quantityToClaim]),
    );

    // Set mint conditions
    const templateMintCondition: any = {
      startTimestamp: BigNumber.from((await ethers.provider.getBlock("latest")).timestamp).add(100),
      maxClaimableSupply: BigNumber.from(25),
      supplyClaimed: BigNumber.from(0),
      waitTimeInSecondsBetweenClaims: BigNumber.from(5),
      merkleRoot: whitelist,
      pricePerToken: ethers.utils.parseEther("0.1"),
      currency: erc20Token.address,
    };

    mintConditions = [...Array(5).keys()]
      .map((val: number) => val * 100)
      .map((val: number) => {
        return {
          ...templateMintCondition,
          startTimestamp: (templateMintCondition.startTimestamp as BigNumber).add(val),
        };
      });

    // Set mint conditions
    await lazyMintERC20.connect(protocolAdmin).setClaimConditions(mintConditions);

    // Travel to mint condition start
    targetMintConditionIndex = BigNumber.from(0);
    await timeTravelToMintCondition(targetMintConditionIndex);

    // Mint erc20 tokens to claimer
    await mintERC20To(claimer, ethers.utils.parseEther("100"));
  });

  describe("Revert cases", function () {
    it("Should revert if quantity wanted is zero", async () => {
      const invalidQty: BigNumber = BigNumber.from(0);
      await expect(lazyMintERC20.connect(claimer).claim(claimer.address, invalidQty, proof)).to.be.revertedWith(
        "invalid quantity claimed.",
      );
    });

    it("Should revert if quantity wanted + current mint supply exceeds max mint supply", async () => {
      let supplyClaimed: BigNumber = BigNumber.from(0);
      const maxClaimableSupply: BigNumber = mintConditions[0].maxClaimableSupply as BigNumber;

      await erc20Token.connect(claimer).approve(lazyMintERC20.address, ethers.constants.MaxUint256);

      while (supplyClaimed.lt(maxClaimableSupply)) {
        if (supplyClaimed.add(quantityToClaim).gt(maxClaimableSupply)) {
          await expect(lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof)).to.be.revertedWith(
            "invalid quantity claimed.",
          );
          break;
        } else {
          await lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof);

          const nextValidTimestampForClaim: BigNumber = await lazyMintERC20.getTimestampForNextValidClaim(
            targetMintConditionIndex,
            claimer.address,
          );
          await ethers.provider.send("evm_mine", [nextValidTimestampForClaim.toNumber()]);

          supplyClaimed = supplyClaimed.add(quantityToClaim);
        }
      }
    });

    it("Should revert if claimer claims before valid timestamp for transaction", async () => {
      await lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof);

      await expect(lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof)).to.be.revertedWith(
        "cannot claim yet.",
      );
    });

    it("Should revert if claimer is not in the whitelist", async () => {
      await expect(lazyMintERC20.connect(protocolAdmin).claim(protocolAdmin.address, quantityToClaim, proof)).to.be.revertedWith(
        "not in whitelist.",
      );
    });

    it("Should revert if caller has not approved lazy mint to transfer currency", async () => {
      // Remove allowance
      await erc20Token
        .connect(claimer)
        .decreaseAllowance(lazyMintERC20.address, await erc20Token.balanceOf(claimer.address));

      await expect(lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof)).to.be.revertedWith(
        "insufficient currency balance or allowance.",
      );
    });
  });

  describe("Events", function () {
    beforeEach(async () => {
      // Mint erc20 tokens to claimer
      await mintERC20To(claimer, ethers.utils.parseEther("100"));
    });

    it("Should emit ClaimedTokens", async () => {
      await expect(lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof))
        .to.emit(lazyMintERC20, "ClaimedTokens")
        .withArgs(
          ...Object.values({
            mintConditionIndex: targetMintConditionIndex,
            claimer: claimer.address,
            receiver: claimer.address,
            quantityClaimed: quantityToClaim,
          }),
        );
    });
  });

  describe("Balances", function () {
    it("Should increase the claimer's balance of the tokens claimed", async () => {
      const claimerBalBefore: BigNumber = await lazyMintERC20.balanceOf(claimer.address);
      await lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof);
      const claimerBalAfter: BigNumber = await lazyMintERC20.balanceOf(claimer.address);

      expect(claimerBalAfter).to.equal(claimerBalBefore.add(quantityToClaim));
    });

    it("Should decrease the currency balance of the claimer", async () => {
      const claimerBalBefore: BigNumber = await erc20Token.balanceOf(claimer.address);
      await lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof);
      const claimerBalAfter: BigNumber = await erc20Token.balanceOf(claimer.address);

      expect(claimerBalAfter).to.equal(claimerBalBefore.sub(totalPrice));
    });

    it("Should distribute the sale value to the relevant stakeholders", async () => {
      // Set fees to 5 %
      const MAX_BPS: BigNumber = BigNumber.from(10_000);
      const feeBps: BigNumber = BigNumber.from(500);
      await lazyMintERC20.connect(protocolAdmin).setFeeBps(feeBps);

      const fees: BigNumber = totalPrice.mul(feeBps).div(MAX_BPS);
      const feeRecipient: string = royaltyTreasury;

      const remainder: BigNumber = totalPrice.sub(fees);
      const remainderRecipient: string = protocolAdmin.address;

      const feeRecipientBalBefore: BigNumber = await erc20Token.balanceOf(feeRecipient);
      const remainderRecipientBalBefore: BigNumber = await erc20Token.balanceOf(remainderRecipient);

      await lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof);

      const feeRecipientBalAfter: BigNumber = await erc20Token.balanceOf(feeRecipient);
      const remainderRecipientBalAfter: BigNumber = await erc20Token.balanceOf(remainderRecipient);

      expect(feeRecipientBalAfter).to.equal(feeRecipientBalBefore.add(fees));
      expect(remainderRecipientBalAfter).to.equal(remainderRecipientBalBefore.add(remainder));
    });
  });

  describe("Contract state", function () {
    it("Should update the supply minted during the claim condition", async () => {
      const currenMintSupplyBefore = (await lazyMintERC20.getClaimConditionAtIndex(targetMintConditionIndex))
        .supplyClaimed;
      await lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof);
      const currenMintSupplyAfter = (await lazyMintERC20.getClaimConditionAtIndex(targetMintConditionIndex))
        .supplyClaimed;

      expect(currenMintSupplyAfter).to.equal(currenMintSupplyBefore.add(quantityToClaim));
    });
    it("Should update the next valid timestamp for claim, for the claimer", async () => {
      const waitBetweenClaims: BigNumber = (await lazyMintERC20.getClaimConditionAtIndex(targetMintConditionIndex))
        .waitTimeInSecondsBetweenClaims;
      await lazyMintERC20.connect(claimer).claim(claimer.address, quantityToClaim, proof);

      const currentTimestamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
      const expectedNextValidTimestamp: BigNumber = currentTimestamp.add(waitBetweenClaims);

      expect(await lazyMintERC20.getTimestampForNextValidClaim(targetMintConditionIndex, claimer.address)).to.equal(
        expectedNextValidTimestamp,
      );
    });
  });
});
