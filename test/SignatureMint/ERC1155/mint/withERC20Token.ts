import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { SignatureMint1155, MintRequestStruct } from "typechain/SignatureMint1155";
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
  let sigMint1155: SignatureMint1155;
  let erc20Token: Coin;

  // Default `mint` params
  let mintRequest: MintRequestStruct;
  let signature: BytesLike;
  let totalPrice: BigNumber;

  before(async () => {
    [protocolProvider, protocolAdmin, requestor] = await ethers.getSigners();
  });

  const mintERC20To = async (to: SignerWithAddress, amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(protocolAdmin).mint(to.address, amount);

    // Approve Market to transfer currency
    await erc20Token.connect(to).approve(sigMint1155.address, amount);
  };

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    sigMint1155 = contracts.sigMint1155;
    erc20Token = contracts.coin;

    const validityStartTimestamp: BigNumber = BigNumber.from((await ethers.provider.getBlock("latest")).timestamp);
    const validityEndTimestamp: BigNumber = validityStartTimestamp.add(100);

    mintRequest = {
      to: requestor.address,
      tokenId: ethers.constants.MaxUint256.toString(),
      uri: "ipfs://test/",
      quantity: 10,
      pricePerToken: ethers.utils.parseEther("0.1").toString(),
      currency: erc20Token.address,
      validityStartTimestamp: validityStartTimestamp.toString(),
      validityEndTimestamp: validityEndTimestamp.toString(),
      uid: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("Some string UID")),
    };

    const signatureResult = await signMintRequest(protocolAdmin.provider, protocolAdmin, sigMint1155, mintRequest);
    signature = signatureResult.signature;

    totalPrice = BigNumber.from(mintRequest.pricePerToken).mul(mintRequest.quantity);

    // Mint erc20 tokens to requestor
    await mintERC20To(requestor, ethers.utils.parseEther("100"));
  });

  describe("Revert cases", function () {
    it("Should revert if the mint request is signed by an account not holding MINTER_ROLE", async () => {
      const invalidSignature: string = (await signMintRequest(requestor.provider, requestor, sigMint1155, mintRequest))
        .signature as string;

      await expect(sigMint1155.connect(requestor).mintWithSignature(mintRequest, invalidSignature)).to.be.revertedWith(
        "invalid signature",
      );
    });

    it("Should revert if the same mint request is used more than once", async () => {
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature);

      await expect(sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature)).to.be.revertedWith(
        "invalid signature",
      );
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
        sigMint1155.connect(requestor).mintWithSignature(expiredMintRequest, signatureOfExpiredReq),
      ).to.be.revertedWith("request expired");
    });

    it("Should revert if the requestor has not approved the total price of the NFTs to mint", async () => {
      await erc20Token
        .connect(requestor)
        .decreaseAllowance(sigMint1155.address, await erc20Token.allowance(requestor.address, sigMint1155.address));

      await expect(
        sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature, { value: 0 }),
      ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });
  });

  describe("Events", function () {
    it("Should emit TokenMinted", async () => {
      const tokenIdToBeMinted = await sigMint1155.nextTokenIdToMint();

      await expect(sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature))
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

      await expect(sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature))
        .to.emit(sigMint1155, "MintWithSignature")
        .withArgs(
          ...Object.values({
            signer: protocolAdmin.address,
            mintedTo: requestor.address,
            tokenIdMinted: tokenIdToBeMinted,
            mintRequest: Object.values({
              to: mintRequest.to,
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
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature);
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
      await sigMint1155.connect(requestor).mintWithSignature(specialMintRequest, signatureToUse);
      const requestorBalAfter = await sigMint1155.balanceOf(requestor.address, tokenIdToBeMinted);

      expect(requestorBalAfter).to.equal(requestorBalBefore.add(mintRequest.quantity));
    });

    it("Should distribute the price of the NFTs minted with a mint request from the requestor to the sale recipient", async () => {
      const saleRecipientAddr: string = await sigMint1155.defaultSaleRecipient();

      const requestorBalBefore: BigNumber = await erc20Token.balanceOf(requestor.address);
      const saleRecipientBalBefore: BigNumber = await erc20Token.balanceOf(saleRecipientAddr);

      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature);

      const requestorBalAfter: BigNumber = await erc20Token.balanceOf(requestor.address);
      const saleRecipientBalAfter: BigNumber = await erc20Token.balanceOf(saleRecipientAddr);

      expect(saleRecipientBalAfter).to.equal(saleRecipientBalBefore.add(totalPrice));
      expect(requestorBalAfter).to.equal(requestorBalBefore.sub(totalPrice));
    });
  });

  describe("Contract state", function () {
    it("Should mark the mint request as already used", async () => {
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature);

      const [success] = await sigMint1155.verify(mintRequest, signature);

      expect(success).to.equal(false);
    });

    it("Should return the URI for a token in the intended baseURI + tokenId format", async () => {
      const tokenIdToCheck: BigNumber = await sigMint1155.nextTokenIdToMint();
      await sigMint1155.connect(requestor).mintWithSignature(mintRequest, signature);

      const uriForToken: string = await sigMint1155.tokenURI(tokenIdToCheck);
      expect(uriForToken).to.equal(mintRequest.uri);
    });
  });
});
