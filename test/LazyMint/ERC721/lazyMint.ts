import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC721 } from "typechain/LazyMintERC721";

// Types
import { BigNumber, BigNumberish, Bytes } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

function xor(data: Uint8Array, key: Uint8Array) {
  const len = data.length;
  const result = [];
  for (let i = 0; i < len; i += 32) {
    const hash = ethers.utils.solidityKeccak256(["bytes", "uint256"], [key, i]);
    const slice = data.slice(i, i + 32);
    const hashsliced = ethers.utils.arrayify(hash).slice(0, slice.length); // weird that we need to slice the hash
    const chunk = ethers.BigNumber.from(slice).xor(hashsliced);
    result.push(chunk);
  }
  return `0x${result.map(chunk => chunk.toHexString().substring(2)).join("")}`;
}

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
    const placeholderURI: string = "ipfs://QmY5vGkXabXJEk8hDq3aJFEg75R7wENZ8xGoUXhF6LsCKA/";
    const secretURI: string = "ipfs://QmTXt3Y2vKEnm6XzGmJcEnGZmihBRZ5RBQVt8RFPBzW69v/";
    const encryptionKey: string = "any key";

    const tokenId: BigNumber = BigNumber.from(999);

    beforeEach(async () => {
      if (this.ctx.currentTest?.title.startsWith("skipBeforeEach:")) {
        return;
      }

      const encrytpedSecretURI: string = await lazyMintERC721.encryptDecrypt(
        ethers.utils.toUtf8Bytes(secretURI),
        ethers.utils.toUtf8Bytes(encryptionKey),
      );
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, placeholderURI, encrytpedSecretURI);
    });

    it("Should return placeholder URI before reveal, and secret URI after", async () => {
      const expectedURIBefore: string = placeholderURI + "0";
      const expectedURIAfter: string = secretURI + tokenId.toString();

      expect(await lazyMintERC721.tokenURI(tokenId)).to.equal(expectedURIBefore);

      const indexForToken = (await lazyMintERC721.getBaseURICount()).sub(1);
      await lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey));

      expect(await lazyMintERC721.tokenURI(tokenId)).to.equal(expectedURIAfter);
    });

    it("skipBeforeEach: mint, reveal, mint, reveal", async () => {
      const encryptedSecretURI: string = await lazyMintERC721.encryptDecrypt(
        ethers.utils.toUtf8Bytes(secretURI),
        ethers.utils.toUtf8Bytes(encryptionKey),
      );

      // 0 - 9999
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, placeholderURI, encryptedSecretURI);

      const expectedURIBefore: string = placeholderURI;
      const expectedURIAfter: string = secretURI;

      expect(await lazyMintERC721.tokenURI(0)).to.equal(`${expectedURIBefore}0`);

      await lazyMintERC721.connect(protocolAdmin).reveal(0, ethers.utils.toUtf8Bytes(encryptionKey));

      expect(await lazyMintERC721.tokenURI(0)).to.equal(`${expectedURIAfter}0`);

      // 10000 - 19999
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, placeholderURI, encryptedSecretURI);

      expect(await lazyMintERC721.tokenURI(10000)).to.equal(`${expectedURIBefore}0`);

      await lazyMintERC721.connect(protocolAdmin).reveal(1, ethers.utils.toUtf8Bytes(encryptionKey));

      expect(await lazyMintERC721.tokenURI(0)).to.equal(`${expectedURIAfter}0`);
      expect(await lazyMintERC721.tokenURI(10000)).to.equal(`${expectedURIAfter}10000`);
    });

    it("skipBeforeEach: mint, mint, reveal, reveal", async () => {
      const encryptedSecretURI: string = await lazyMintERC721.encryptDecrypt(
        ethers.utils.toUtf8Bytes(secretURI),
        ethers.utils.toUtf8Bytes(encryptionKey),
      );

      // 0 - 9999
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, placeholderURI, encryptedSecretURI);
      // 10000 - 19999
      await lazyMintERC721.connect(protocolAdmin).lazyMint(amountToLazyMint, placeholderURI, encryptedSecretURI);

      const expectedURIBefore: string = placeholderURI;
      const expectedURIAfter: string = secretURI;

      expect(await lazyMintERC721.tokenURI(0)).to.equal(`${expectedURIBefore}0`);
      expect(await lazyMintERC721.tokenURI(10000)).to.equal(`${expectedURIBefore}0`);

      await lazyMintERC721.connect(protocolAdmin).reveal(0, ethers.utils.toUtf8Bytes(encryptionKey));

      expect(await lazyMintERC721.tokenURI(0)).to.equal(`${expectedURIAfter}0`);
      expect(await lazyMintERC721.tokenURI(10000)).to.equal(`${expectedURIBefore}0`);

      await lazyMintERC721.connect(protocolAdmin).reveal(1, ethers.utils.toUtf8Bytes(encryptionKey));

      expect(await lazyMintERC721.tokenURI(0)).to.equal(`${expectedURIAfter}0`);
      expect(await lazyMintERC721.tokenURI(10000)).to.equal(`${expectedURIAfter}10000`);
    });

    it("Should revert if reveal has already happened", async () => {
      const indexForToken = 0;
      await lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey));

      await expect(
        lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes("some other key")),
      ).to.be.revertedWith("nothing to reveal.");
    });

    it("Should revert if non existent index is provided", async () => {
      const indexForToken = await lazyMintERC721.getBaseURICount();

      await expect(
        lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey)),
      ).to.be.revertedWith("invalid index.");
    });

    it("Should be reverted if NFTs at given index are not delayed reveal NFTs", async () => {
      await lazyMintERC721
        .connect(protocolAdmin)
        .lazyMint(amountToLazyMint, placeholderURI, ethers.utils.toUtf8Bytes(""));

      const indexForToken = (await lazyMintERC721.getBaseURICount()).sub(1);
      await expect(
        lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey)),
      ).to.be.revertedWith("nothing to reveal.");
    });

    it("Should emit RevealedNFT with the revealed URI", async () => {
      const expectedRevealedURI: string = secretURI;
      const indexForToken = (await lazyMintERC721.getBaseURICount()).sub(1);

      await expect(lazyMintERC721.connect(protocolAdmin).reveal(indexForToken, ethers.utils.toUtf8Bytes(encryptionKey)))
        .to.emit(lazyMintERC721, "RevealedNFT")
        .withArgs(
          ...Object.values({
            endTokenId: await lazyMintERC721.baseURIIndices(indexForToken),
            revealedURI: expectedRevealedURI,
          }),
        );
    });

    it("skipBeforeEach: Should not reveal the password on-chain", async () => {
      const contract = lazyMintERC721.connect(protocolAdmin);

      async function hashPassword(password: string) {
        const chainId = (await ethers.provider.getNetwork()).chainId;
        const contractAddress = lazyMintERC721.address;
        const indexForToken = await contract.getBaseURICount();
        return ethers.utils.solidityKeccak256(
          ["string", "uint256", "uint256", "address"],
          [password, chainId, indexForToken, contractAddress],
        );
      }

      const password1 = await hashPassword(encryptionKey);
      await contract.lazyMint(
        amountToLazyMint,
        placeholderURI,
        await contract.encryptDecrypt(ethers.utils.toUtf8Bytes(secretURI), password1),
      );

      const log = (await (await contract.reveal(0, password1)).wait()).logs[0];
      const revealedURI = contract.interface.decodeEventLog("RevealedNFT", log.data, log.topics).revealedURI;
      expect(revealedURI).to.equal(secretURI);

      const password2 = await hashPassword(encryptionKey);
      await contract.lazyMint(
        amountToLazyMint,
        placeholderURI,
        await contract.encryptDecrypt(ethers.utils.toUtf8Bytes("ipfs://some_cid_hash/"), password2),
      );

      // password1 has already been published
      await expect(contract.callStatic.reveal(1, password1)).to.reverted;
      expect(await contract.callStatic.reveal(1, password2)).to.equal("ipfs://some_cid_hash/");
    });
  });
});
