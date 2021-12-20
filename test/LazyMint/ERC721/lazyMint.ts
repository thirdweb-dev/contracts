import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC721 } from "typechain/LazyMintERC721";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Test: lazy mint tokens", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let defaultSaleRecipient: SignerWithAddress;

  // Contracts
  let lazyMintERC721: LazyMintERC721;

  // Lazy minting params
  const amountToLazyMint: BigNumber = BigNumber.from(10_000);
  const baseURI: string = "ipfs://baseURI/";

  before(async () => {
    [protocolProvider, protocolAdmin, defaultSaleRecipient] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    lazyMintERC721 = contracts.lazyMintERC721;
  });

  describe("Revert cases", function () {
    it("Should revert if caller does not have minter role", async () => {
      await expect(lazyMintERC721.connect(defaultSaleRecipient).lazyMint(amountToLazyMint, baseURI)).to.be.revertedWith(
        "not minter.",
      );
    });
  });

  describe("Events", function () {
    it("Should emit LazyMintedTokens", async () => {
      const expectedStartTokenId: BigNumber = await lazyMintERC721.nextTokenIdToMint();
      const expectedEndTokenId: BigNumber = expectedStartTokenId.add(amountToLazyMint).sub(1);

      await expect(lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI))
        .to.emit(lazyMintERC721, "LazyMintedTokens")
        .withArgs(
          ...Object.values({
            startTokenId: expectedStartTokenId,
            endTokenId: expectedEndTokenId,
            baseURI: baseURI,
          }),
        );
    });
  });

  describe("Contract state", function () {
    it("Should increment the 'nextTokenIdToMint' by the amount of tokens lazy minted", async () => {
      const nextIdToMintBefore: BigNumber = await lazyMintERC721.nextTokenIdToMint();
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI);
      const nextIdToMintAfter: BigNumber = await lazyMintERC721.nextTokenIdToMint();

      expect(nextIdToMintAfter).to.equal(nextIdToMintBefore.add(amountToLazyMint));
    });

    it("Should return the URI for any token in the baseURI + tokenId convention", async () => {
      const tokenIdToCheck: BigNumber = BigNumber.from(9999);
      const expectedURI: string = baseURI + tokenIdToCheck.toString();

      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI);

      expect(await lazyMintERC721.tokenURI(tokenIdToCheck)).to.equal(expectedURI);
    });
  });
});
