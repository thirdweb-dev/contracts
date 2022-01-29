import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { SignatureMint721, MintRequestStruct } from "typechain/SignatureMint721";
import { Coin } from "typechain/Coin";

// Types
import { BigNumber, BytesLike } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";

// Signature utils
const { signMintRequest } = require("./utils/sign");

use(solidity);

describe("Mint tokens with a valid mint request", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let requestor: SignerWithAddress;

  // Contracts
  let sigMint721: SignatureMint721;
  let erc20Token: Coin;

  // Default `mint` params
  let mintRequest: MintRequestStruct;
  let signature: BytesLike;
  let totalPrice: BigNumber;

  const mintERC20To = async (to: SignerWithAddress, amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(protocolAdmin).mint(to.address, amount);

    // Approve Market to transfer currency
    await erc20Token.connect(to).approve(sigMint721.address, amount);
  };

  before(async () => {
    [protocolProvider, protocolAdmin, requestor] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    sigMint721 = contracts.sigMint721;
    erc20Token = contracts.coin;

    const validityStartTimestamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
    const validityEndTimestamp: BigNumber = validityStartTimestamp.add(100);

    mintRequest = {
      to: requestor.address,
      uri: "ipfs://test/",
      price: ethers.utils.parseEther("0.1").toString(),
      currency: erc20Token.address,
      validityStartTimestamp: validityStartTimestamp.toString(),
      validityEndTimestamp: validityEndTimestamp.toString(),
      uid: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("Some string UID")),
    };

    const signatureResult = await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint721, mintRequest);
    signature = signatureResult.signature;

    totalPrice = BigNumber.from(mintRequest.price);

    // Mint erc20 tokens to requestor
    await mintERC20To(requestor, ethers.utils.parseEther("100"));
  });

  describe("Revert cases", function () {
    it("Should revert if the mint request is signed by an account not holding MINTER_ROLE", async () => {
      const invalidSignature: string = (await signMintRequest(requestor.provider, requestor, sigMint721, mintRequest))
        .signature as string;

      await expect(sigMint721.connect(requestor).mintWithSignature(mintRequest, invalidSignature)).to.be.revertedWith(
        "invalid signature",
      );
    });

    it("Should revert if the same mint request is used more than once", async () => {
      await sigMint721.connect(requestor).mintWithSignature(mintRequest, signature);

      await expect(sigMint721.connect(requestor).mintWithSignature(mintRequest, signature)).to.be.revertedWith(
        "invalid signature",
      );
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
        sigMint721.connect(requestor).mintWithSignature(expiredMintRequest, signatureOfExpiredReq),
      ).to.be.revertedWith("request expired");
    });

    it("Should revert if the requestor has not approved the total price of the NFTs to mint", async () => {
      await erc20Token
        .connect(requestor)
        .decreaseAllowance(sigMint721.address, await erc20Token.allowance(requestor.address, sigMint721.address));

      await expect(
        sigMint721.connect(requestor).mintWithSignature(mintRequest, signature, { value: 0 }),
      ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });
  });

  describe("Events", function () {
    it("Should emit TokenMinted", async () => {
      const tokenIdToBeMinted = await sigMint721.nextTokenIdToMint();

      await expect(sigMint721.connect(requestor).mintWithSignature(mintRequest, signature))
        .to.emit(sigMint721, "TokenMinted")
        .withArgs(
          ...Object.values({
            mintedTo: requestor.address,
            tokenIdMinted: tokenIdToBeMinted,
            uri: mintRequest.uri,
          }),
        );
    });

    it("Should emit MintWithSignature.", async () => {
      const tokenIdThatWillBeMinted: BigNumber = await sigMint721.nextTokenIdToMint();

      await expect(sigMint721.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice }))
        .to.emit(sigMint721, "MintWithSignature")
        .withArgs(
          ...Object.values({
            signer: protocolAdmin.address,
            mintedTo: requestor.address,
            tokenIdMinted: tokenIdThatWillBeMinted,
            mintRequest: Object.values({
              to: mintRequest.to,
              uri: mintRequest.uri,
              price: mintRequest.price,
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
    it("Should increase the requestor's NFT balance by the `amountToMint` specified in the mint request", async () => {
      const tokenIdToBeMintedBefore: number = (await sigMint721.nextTokenIdToMint()).toNumber();
      await sigMint721.connect(requestor).mintWithSignature(mintRequest, signature);
      const tokenIdToBeMintedAfter: number = (await sigMint721.nextTokenIdToMint()).toNumber();

      for (let i = tokenIdToBeMintedBefore; i < tokenIdToBeMintedAfter; i += 1) {
        expect(await sigMint721.ownerOf(i)).to.equal(requestor.address);
      }
    });

    it("Should increase the caller's NFT balance by 1, if mint request does not specify a recipient", async () => {
      const specialMintRequest = { ...mintRequest, to: ethers.constants.AddressZero };
      const signatureToUse = (
        await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint721, specialMintRequest)
      ).signature;

      const tokenIdToBeMintedBefore: number = (await sigMint721.nextTokenIdToMint()).toNumber();
      await sigMint721.connect(requestor).mintWithSignature(specialMintRequest, signatureToUse);
      const tokenIdToBeMintedAfter: number = (await sigMint721.nextTokenIdToMint()).toNumber();

      for (let i = tokenIdToBeMintedBefore; i < tokenIdToBeMintedAfter; i += 1) {
        expect(await sigMint721.ownerOf(i)).to.equal(requestor.address);
      }
    });

    it("Should distribute the price of the NFTs minted with a mint request from the requestor to the sale recipient", async () => {
      const saleRecipientAddr: string = await sigMint721.defaultSaleRecipient();

      const requestorBalBefore: BigNumber = await erc20Token.balanceOf(requestor.address);
      const saleRecipientBalBefore: BigNumber = await erc20Token.balanceOf(saleRecipientAddr);

      await sigMint721.connect(requestor).mintWithSignature(mintRequest, signature);

      const requestorBalAfter: BigNumber = await erc20Token.balanceOf(requestor.address);
      const saleRecipientBalAfter: BigNumber = await erc20Token.balanceOf(saleRecipientAddr);

      expect(saleRecipientBalAfter).to.equal(saleRecipientBalBefore.add(totalPrice));
      expect(requestorBalAfter).to.equal(requestorBalBefore.sub(totalPrice));
    });
  });

  describe("Contract state", function () {
    it("Should increment the `nextTokenIdToMint` by the amount of NFTs minted", async () => {
      const tokenIdToBeMintedBefore: number = (await sigMint721.nextTokenIdToMint()).toNumber();
      await sigMint721.connect(requestor).mintWithSignature(mintRequest, signature);
      const tokenIdToBeMintedAfter: number = (await sigMint721.nextTokenIdToMint()).toNumber();

      expect(tokenIdToBeMintedAfter).to.equal(tokenIdToBeMintedBefore + 1);
    });

    it("Should mark the mint request as already used", async () => {
      await sigMint721.connect(requestor).mintWithSignature(mintRequest, signature, { value: totalPrice });

      const [success] = await sigMint721.verify(mintRequest, signature);

      expect(success).to.equal(false);
    });

    it("Should return the URI for a token in the intended baseURI + tokenId format", async () => {
      const tokenIdToCheck: BigNumber = await sigMint721.nextTokenIdToMint();
      await sigMint721.connect(requestor).mintWithSignature(mintRequest, signature);

      const uriForToken: string = await sigMint721.tokenURI(tokenIdToCheck);
      expect(uriForToken).to.equal(mintRequest.uri);
    });
  });
});
