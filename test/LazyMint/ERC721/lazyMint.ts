import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC721 } from "typechain/LazyMintERC721";

// Types
import { BigNumber, Bytes } from "ethers";
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
      await expect(
        lazyMintERC721.connect(defaultSaleRecipient).lazyMint(amountToLazyMint, baseURI, ethers.utils.toUtf8Bytes("")),
      ).to.be.revertedWith("not minter.");
    });
  });

  describe("Events", function () {
    it("Should emit LazyMintedTokens", async () => {
      const expectedStartTokenId: BigNumber = await lazyMintERC721.nextTokenIdToMint();
      const expectedEndTokenId: BigNumber = expectedStartTokenId.add(amountToLazyMint).sub(1);

      await expect(
        lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI, ethers.utils.toUtf8Bytes("")),
      )
        .to.emit(lazyMintERC721, "LazyMintedTokens")
        .withArgs(
          ...Object.values({
            startTokenId: expectedStartTokenId,
            endTokenId: expectedEndTokenId,
            baseURI: baseURI,
            encryptedBaseURI: ethers.utils.toUtf8Bytes(""),
          }),
        );
    });
  });

  describe("Contract state", function () {
    it("Should increment the 'nextTokenIdToMint' by the amount of tokens lazy minted", async () => {
      const nextIdToMintBefore: BigNumber = await lazyMintERC721.nextTokenIdToMint();
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI, ethers.utils.toUtf8Bytes(""));
      const nextIdToMintAfter: BigNumber = await lazyMintERC721.nextTokenIdToMint();

      expect(nextIdToMintAfter).to.equal(nextIdToMintBefore.add(amountToLazyMint));
    });

    it("Should return the URI for any token in the baseURI + tokenId convention", async () => {
      const tokenIdToCheck: BigNumber = BigNumber.from(9999);
      const expectedURI: string = baseURI + tokenIdToCheck.toString();

      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI, ethers.utils.toUtf8Bytes(""));

      expect(await lazyMintERC721.tokenURI(tokenIdToCheck)).to.equal(expectedURI);
    });
  });

  describe("Delayed reveal tests", function () {
    const placeholderURI: string = "ipfs://placeholder/";
    const secretURI: string = "ipfs://secret/";
    const encryptionKey: string = "any key";

    const tokenId: BigNumber = BigNumber.from(999);

    beforeEach(async () => {
      const encrytpedSecretURI: string = await lazyMintERC721.encryptDecrypt(
        ethers.utils.toUtf8Bytes(secretURI),
        ethers.utils.toUtf8Bytes(encryptionKey),
      );
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, placeholderURI, encrytpedSecretURI);
    });

    it("Should return placeholder URI before reveal, and secret URI after", async () => {
      const expectedURIBefore: string = placeholderURI + tokenId.toString();
      const expectedURIAfter: string = secretURI + tokenId.toString();

      expect(await lazyMintERC721.tokenURI(tokenId)).to.equal(expectedURIBefore);

      const indexForToken = await lazyMintERC721.getBaseUriIndexOf(tokenId);
      await lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey));

      expect(await lazyMintERC721.tokenURI(tokenId)).to.equal(expectedURIAfter);
    });

    it("Should revert if reveal has already happened", async () => {
      const indexForToken = await lazyMintERC721.getBaseUriIndexOf(tokenId);
      await lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey));

      await expect(
        lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes("some other key")),
      ).to.be.revertedWith("nothing to reveal.");
    });

    it("Should revert if non existent index is provided", async () => {
      const indexForToken: BigNumber = await lazyMintERC721.getBaseUriIndexOf(tokenId);

      await expect(
        lazyMintERC721.connect(protocolAdmin).reveal(indexForToken.add(1), ethers.utils.toUtf8Bytes(encryptionKey)),
      ).to.be.revertedWith("invalid index.");
    });

    it("Should be reverted if NFTs at given index are not delayed reveal NFTs", async () => {
      const nextTokenIdToBeMinted = await lazyMintERC721.nextTokenIdToMint();

      await lazyMintERC721
        .connect(protocolAdmin)
        .lazyMint(amountToLazyMint, placeholderURI, ethers.utils.toUtf8Bytes(""));

      const indexForToken = await lazyMintERC721.getBaseUriIndexOf(nextTokenIdToBeMinted);
      await expect(
        lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey)),
      ).to.be.revertedWith("nothing to reveal.");
    });

    it("Should emit RevealedNFT with the revealed URI", async () => {
      const expectedRevealedURI: string = secretURI;
      const indexForToken = await lazyMintERC721.getBaseUriIndexOf(tokenId);

      await expect(lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey)))
        .to.emit(lazyMintERC721, "RevealedNFT")
        .withArgs(
          ...Object.values({
            endTokenId: indexForToken,
            revealedURI: expectedRevealedURI,
          }),
        );
    });
  });
});
