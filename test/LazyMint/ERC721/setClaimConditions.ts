import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC721, ClaimConditionStruct } from "typechain/LazyMintERC721";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Test: claim conditions", function () {
  // Constants
  const NATIVE_TOKEN_ADDRESS: string = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;

  // Contracts
  let lazyMintERC721: LazyMintERC721;

  // Lazy minting params
  const amountToLazyMint: BigNumber = BigNumber.from(10_000);
  const baseURI: string = "ipfs://baseURI/";

  // Setting mint conditions default params
  let claimConditions: ClaimConditionStruct[];

  before(async () => {
    [protocolProvider, protocolAdmin] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    lazyMintERC721 = contracts.lazyMintERC721;

    // Lazy mint tokens
    await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI);

    // Set mint conditions
    const templateMintCondition: ClaimConditionStruct = {
      startTimestamp: BigNumber.from((await ethers.provider.getBlock("latest")).timestamp).add(100),
      maxClaimableSupply: BigNumber.from(100),
      supplyClaimed: BigNumber.from(0),
      quantityLimitPerTransaction: BigNumber.from(5),
      waitTimeInSecondsBetweenClaims: BigNumber.from(100),
      merkleRoot: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test")),
      pricePerToken: ethers.utils.parseEther("0.1"),
      currency: NATIVE_TOKEN_ADDRESS,
    };

    claimConditions = [...Array(5).keys()]
      .map((val: number) => val * 100)
      .map((val: number) => {
        return {
          ...templateMintCondition,
          startTimestamp: (templateMintCondition.startTimestamp as BigNumber).add(val),
        };
      });
  });

  describe("Revert cases", function () {
    it("Should revert if mint conditions are not in ascending order by timestamp", async () => {
      const temp: ClaimConditionStruct = claimConditions[0];
      claimConditions[0] = claimConditions[claimConditions.length - 1];
      claimConditions[claimConditions.length - 1] = temp;

      await expect(
        lazyMintERC721.connect(protocolAdmin).setClaimConditions(claimConditions),
      ).to.be.revertedWith("startTimestamp must be in ascending order");
    });

    it("Should revert if max mint supply is zero", async () => {
      claimConditions[0].maxClaimableSupply = 0;

      await expect(
        lazyMintERC721.connect(protocolAdmin).setClaimConditions(claimConditions),
      ).to.be.revertedWith("max mint supply cannot be 0");
    });

    it("Should revert if quantity limit per claim transaction is zero", async () => {
      claimConditions[0].quantityLimitPerTransaction = 0;

      await expect(
        lazyMintERC721.connect(protocolAdmin).setClaimConditions(claimConditions),
      ).to.be.revertedWith("quantity limit cannot be 0");
    });
  });

  describe("Events", function () {
    it("Should emit NewClaimConditions", async () => {
      await expect(lazyMintERC721.connect(protocolAdmin).setClaimConditions(claimConditions)).to.emit(
        lazyMintERC721,
        "NewClaimConditions",
      );
    });
  });

  describe("Contract state", function () {
    it("Should increment the condition index to use for future mint conditions", async () => {
      const indexBefore: BigNumber = (await lazyMintERC721.claimConditions()).totalConditionCount; // returns `totalConditionCount` from `PublicclaimConditions`
      await lazyMintERC721.connect(protocolAdmin).setClaimConditions(claimConditions);
      const indexAfter: BigNumber = (await lazyMintERC721.claimConditions()).totalConditionCount; // returns `totalConditionCount` from `PublicclaimConditions`

      expect(indexAfter).to.equal(indexBefore.add(claimConditions.length));
    });

    it("Should store each mint condition at the right index", async () => {
      const indexBefore: BigNumber = (await lazyMintERC721.claimConditions()).totalConditionCount; // returns `totalConditionCount` from `PublicclaimConditions`
      await lazyMintERC721.connect(protocolAdmin).setClaimConditions(claimConditions);
      const nextIndex: BigNumber = (await lazyMintERC721.claimConditions()).totalConditionCount; // returns `totalConditionCount` from `PublicclaimConditions`

      for (let i = indexBefore.toNumber(); i < nextIndex.toNumber(); i += 1) {
        const condition: ClaimConditionStruct = await lazyMintERC721.getClaimConditionAtIndex(i);

        expect(condition.startTimestamp).to.equal(claimConditions[i].startTimestamp);
        expect(condition.maxClaimableSupply).to.equal(claimConditions[i].maxClaimableSupply);
        expect(condition.supplyClaimed).to.equal(claimConditions[i].supplyClaimed);
        expect(condition.quantityLimitPerTransaction).to.equal(claimConditions[i].quantityLimitPerTransaction);
        expect(condition.waitTimeInSecondsBetweenClaims).to.equal(claimConditions[i].waitTimeInSecondsBetweenClaims);
        expect(condition.merkleRoot).to.equal(claimConditions[i].merkleRoot);
        expect(condition.pricePerToken).to.equal(claimConditions[i].pricePerToken);
        expect(condition.currency).to.equal(claimConditions[i].currency);
      }
    });
  });
});
