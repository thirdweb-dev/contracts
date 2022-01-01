import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { SignatureMint721, MintRequestStruct } from "typechain/SignatureMint721";

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
  let sigMint721: SignatureMint721;

  // Default `mint` params
  let mintRequest: MintRequestStruct;
  let signature: BytesLike;
  let totalPrice: BigNumber;

  before(async () => {
    [protocolProvider, protocolAdmin, requestor] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    sigMint721 = contracts.sigMint721;

    const validityStartTimestamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
    const validityEndTimestamp: BigNumber = validityStartTimestamp.add(100);

    mintRequest = {
      to: requestor.address,
      baseURI: "ipfs://test/",
      amountToMint: BigNumber.from(5).toString(),
      pricePerToken: ethers.utils.parseEther("0.1").toString(),
      currency: NATIVE_TOKEN_ADDRESS,
      validityStartTimestamp: validityStartTimestamp.toString(),
      validityEndTimestamp: validityEndTimestamp.toString(),
      uid: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("Some string UID")),
    };

    const signatureResult = await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint721, mintRequest);
    signature = signatureResult.signature;

    totalPrice = BigNumber.from(mintRequest.pricePerToken).mul(BigNumber.from(mintRequest.amountToMint));
  });

  describe("Revert cases", function () {
    it("Should revert if the mint request is signed by an account not holding MINTER_ROLE", async () => {
      const invalidSignature: string = (await signMintRequest(requestor.provider, requestor, sigMint721, mintRequest))
        .signature as string;

      await expect(
        sigMint721.connect(requestor).mint(mintRequest, invalidSignature, { value: totalPrice }),
      ).to.be.revertedWith("invalid signature");
    });

    it("Should revert if the same mint request is used more than once", async () => {
      await sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice });

      await expect(
        sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice }),
      ).to.be.revertedWith("invalid signature");
    });

    it("Should revert if the mint request has expired", async () => {
      const expiredMintRequest: MintRequestStruct = {
        ...mintRequest,
        validityEndTimestamp: mintRequest.validityStartTimestamp,
      };
      const signatureOfExpiredReq: string = (
        await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint721, expiredMintRequest)
      ).signature;

      await expect(
        sigMint721.connect(requestor).mint(expiredMintRequest, signatureOfExpiredReq, { value: totalPrice }),
      ).to.be.revertedWith("request expired");
    });

    it("Should revert if the requestor has not sent the total price of the NFTs to mint", async () => {
      await expect(sigMint721.connect(requestor).mint(mintRequest, signature, { value: 0 })).to.be.revertedWith(
        "must send total price.",
      );
    });
  });

  describe("Events", function () {
    it("Should emit TokensMinted with the mint request, signature, and the requestor's address.", async () => {
      await expect(sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice }))
        .to.emit(sigMint721, "TokensMinted")
        .withArgs(
          ...Object.values({
            mintRequest: Object.values({
              to: mintRequest.to,
              baseURI: mintRequest.baseURI,
              amountToMint: mintRequest.amountToMint,
              pricePerToken: mintRequest.pricePerToken,
              currency: mintRequest.currency,
              validityStartTimestamp: mintRequest.validityStartTimestamp,
              validityEndTimestamp: mintRequest.validityEndTimestamp,
              uid: mintRequest.uid,
            }),
            signature: signature,
            requestor: requestor.address,
          }),
        );
    });
  });

  describe("Balances", function () {
    it("Should increase the requestor's NFT balance by the `amountToMint` specified in the mint request", async () => {
      const tokenIdToBeMintedBefore: number = (await sigMint721.nextTokenIdToMint()).toNumber();
      await sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice });
      const tokenIdToBeMintedAfter: number = (await sigMint721.nextTokenIdToMint()).toNumber();

      for (let i = tokenIdToBeMintedBefore; i < tokenIdToBeMintedAfter; i += 1) {
        expect(await sigMint721.ownerOf(i)).to.equal(requestor.address);
      }
    });

    it("Should distribute the price of the NFTs minted with a mint request from the requestor to the sale recipient", async () => {
      const saleRecipientAddr: string = await sigMint721.defaultSaleRecipient();

      const requestorBalBefore: BigNumber = await ethers.provider.getBalance(requestor.address);
      const saleRecipientBalBefore: BigNumber = await ethers.provider.getBalance(saleRecipientAddr);

      const gasPrice: BigNumber = ethers.utils.parseUnits("10", "gwei");
      const tx = await sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice, gasPrice });
      const gasUsed: BigNumber = (await tx.wait()).gasUsed;

      const requestorBalAfter: BigNumber = await ethers.provider.getBalance(requestor.address);
      const saleRecipientBalAfter: BigNumber = await ethers.provider.getBalance(saleRecipientAddr);

      expect(saleRecipientBalAfter).to.equal(saleRecipientBalBefore.add(totalPrice));
      expect(requestorBalAfter).to.equal(requestorBalBefore.sub(totalPrice.add(gasPrice.mul(gasUsed))));
    });
  });

  describe("Contract state", function () {
    it("Should increment the `nextTokenIdToMint` by the amount of NFTs minted", async () => {
      const tokenIdToBeMintedBefore: number = (await sigMint721.nextTokenIdToMint()).toNumber();
      await sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice });
      const tokenIdToBeMintedAfter: number = (await sigMint721.nextTokenIdToMint()).toNumber();

      expect(tokenIdToBeMintedAfter).to.equal(BigNumber.from(mintRequest.amountToMint).add(tokenIdToBeMintedBefore));
    });

    it("Should mark the mint request as already used", async () => {
      await sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice });

      expect(await sigMint721.verify(mintRequest, signature)).to.equal(false);
    });

    it("Should return the URI for a token in the intended baseURI + tokenId format", async () => {
      const tokenIdToCheck: BigNumber = await sigMint721.nextTokenIdToMint();
      await sigMint721.connect(requestor).mint(mintRequest, signature, { value: totalPrice });

      const uriForToken: string = await sigMint721.tokenURI(tokenIdToCheck);
      expect(uriForToken).to.equal(mintRequest.baseURI + tokenIdToCheck.toString());
    });
  });
});
