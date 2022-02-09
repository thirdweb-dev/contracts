import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { SignatureMint1155, MintRequestStruct } from "typechain/SignatureMint1155";

// Types
import { BigNumber, BytesLike } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";

// Signature utils
const { signMintRequest } = require("./utils/sign");

use(solidity);

describe("Mint tokens with a valid mint request", function () {
  const NATIVE_TOKEN_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let requestor: SignerWithAddress;

  // Contracts
  let sigMint1155: SignatureMint1155;

  // Default `mint` params
  let mintRequest: MintRequestStruct;
  let signature: BytesLike;
  let totalPrice: BigNumber;

  before(async () => {
    [protocolProvider, protocolAdmin, requestor] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    sigMint1155 = contracts.sigMint1155;

    const validityStartTimestamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
    const validityEndTimestamp: BigNumber = validityStartTimestamp.add(100);

    mintRequest = {
      to: requestor.address,
      royaltyRecipient: protocolAdmin.address,
      tokenId: ethers.constants.MaxUint256.toString(),
      uri: "ipfs://test/",
      quantity: 10,
      pricePerToken: ethers.utils.parseEther("0.1").toString(),
      currency: NATIVE_TOKEN_ADDRESS,
      validityStartTimestamp: validityStartTimestamp.toString(),
      validityEndTimestamp: validityEndTimestamp.toString(),
      uid: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("Some string UID")),
    };

    const signatureResult = await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint1155, mintRequest);
    signature = signatureResult.signature;

    totalPrice = BigNumber.from(mintRequest.pricePerToken).mul(mintRequest.quantity);
  });

  describe("Revert cases", function () {
    it("Should revert if the mint request is signed by an account not holding MINTER_ROLE", async () => {
      const invalidSignature: string = (await signMintRequest(requestor.provider, requestor, sigMint1155, mintRequest))
        .signature as string;

      await expect(
        sigMint1155.connect(requestor).mintWithSignature(mintRequest, invalidSignature, { value: totalPrice }),
      ).to.be.revertedWith("invalid signature");
    });

    it("Should revert if the same mint request is used more than once", async () => {
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice });

      await expect(
        sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice }),
      ).to.be.revertedWith("invalid signature");
    });

    it("Should revert if the mint request has expired", async () => {
      const expiredMintRequest: MintRequestStruct = {
        ...mintRequest,
        validityEndTimestamp: mintRequest.validityStartTimestamp,
      };
      const signatureOfExpiredReq: string = (
        await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint1155, expiredMintRequest)
      ).signature;

      await expect(
        sigMint1155
          .connect(requestor)
          .mintWithSignature(expiredMintRequest, signatureOfExpiredReq, { value: totalPrice }),
      ).to.be.revertedWith("request expired");
    });

    it("Should revert if the requestor has not sent the total price of the NFTs to mint", async () => {
      await expect(
        sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: 0 }),
      ).to.be.revertedWith("must send total price.");
    });

    it("Should revert if the tokenId provided is not reserved, and not already minted", async () => {
      const invalidMintReq = { ...mintRequest, tokenId: 5 };
      const signatureToUse = (await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint1155, invalidMintReq))
        .signature;

      await expect(
        sigMint1155.connect(requestor).mintWithSignature(invalidMintReq, signatureToUse, { value: totalPrice }),
      ).to.be.revertedWith("invalid id");
    });
  });

  describe("Events", function () {
    it("Should emit TokenMinted", async () => {
      const tokenIdToBeMinted = await sigMint1155.nextTokenIdToMint();

      await expect(sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice }))
        .to.emit(sigMint1155, "TokenMinted")
        .withArgs(
          ...Object.values({
            mintedTo: requestor.address,
            tokenIdMinted: tokenIdToBeMinted,
            uri: mintRequest.uri,
            quantityMinted: mintRequest.quantity,
          }),
        );
    });

    it("Should emit MintWithSignature.", async () => {
      const tokenIdToBeMinted = await sigMint1155.nextTokenIdToMint();

      await expect(sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice }))
        .to.emit(sigMint1155, "MintWithSignature")
        .withArgs(
          ...Object.values({
            signer: protocolAdmin.address,
            mintedTo: requestor.address,
            tokenIdMinted: tokenIdToBeMinted,
            mintRequest: Object.values({
              to: mintRequest.to,
              royaltyRecipient: mintRequest.royaltyRecipient,
              tokenId: mintRequest.tokenId,
              uri: mintRequest.uri,
              quantity: mintRequest.quantity,
              price: mintRequest.pricePerToken,
              currency: mintRequest.currency,
              validityStartTimestamp: mintRequest.validityStartTimestamp,
              validityEndTimestamp: mintRequest.validityEndTimestamp,
              uid: mintRequest.uid,
            }),
          }),
        );
    });
  });

  describe("Balances", function () {
    it("Should increase the requestor's NFT balance by the specified quantity", async () => {
      const tokenIdToBeMinted = await sigMint1155.nextTokenIdToMint();

      const requestorBalBefore = await sigMint1155.balanceOf(requestor.address, tokenIdToBeMinted);
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice });
      const requestorBalAfter = await sigMint1155.balanceOf(requestor.address, tokenIdToBeMinted);

      expect(requestorBalAfter).to.equal(requestorBalBefore.add(mintRequest.quantity));
    });

    it("Should increase the caller's NFT balance by 1, if mint request does not specify a recipient", async () => {
      const tokenIdToBeMinted = await sigMint1155.nextTokenIdToMint();

      const specialMintRequest = { ...mintRequest, to: ethers.constants.AddressZero };
      const signatureToUse = (
        await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint1155, specialMintRequest)
      ).signature;

      const requestorBalBefore = await sigMint1155.balanceOf(requestor.address, tokenIdToBeMinted);
      await sigMint1155.connect(requestor).mintWithSignature(specialMintRequest, signatureToUse, { value: totalPrice });
      const requestorBalAfter = await sigMint1155.balanceOf(requestor.address, tokenIdToBeMinted);

      expect(requestorBalAfter).to.equal(requestorBalBefore.add(mintRequest.quantity));
    });

    it("Should distribute the price of the NFTs minted with a mint request from the requestor to the sale recipient", async () => {
      const saleRecipientAddr: string = await sigMint1155.defaultSaleRecipient();

      const requestorBalBefore: BigNumber = await ethers.provider.getBalance(requestor.address);
      const saleRecipientBalBefore: BigNumber = await ethers.provider.getBalance(saleRecipientAddr);

      const gasPrice: BigNumber = ethers.utils.parseUnits("10", "gwei");
      const tx = await sigMint1155
        .connect(requestor)
        .mintWithSignature(mintRequest, signature, { value: totalPrice, gasPrice });
      const gasUsed: BigNumber = (await tx.wait()).gasUsed;

      const requestorBalAfter: BigNumber = await ethers.provider.getBalance(requestor.address);
      const saleRecipientBalAfter: BigNumber = await ethers.provider.getBalance(saleRecipientAddr);

      expect(saleRecipientBalAfter).to.equal(saleRecipientBalBefore.add(totalPrice));
      expect(requestorBalAfter).to.equal(requestorBalBefore.sub(totalPrice.add(gasPrice.mul(gasUsed))));
    });
  });

  describe("Contract state", function () {
    it("Should mark the mint request as already used", async () => {
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice });

      const [success] = await sigMint1155.verify(mintRequest, signature);

      expect(success).to.equal(false);
    });

    it("Should return the URI for a token in the intended baseURI + tokenId format", async () => {
      const tokenIdToCheck: BigNumber = await sigMint1155.nextTokenIdToMint();
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice });

      const uriForToken: string = await sigMint1155.tokenURI(tokenIdToCheck);
      expect(uriForToken).to.equal(mintRequest.uri);
    });
  });
});
