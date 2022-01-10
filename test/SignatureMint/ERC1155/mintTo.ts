import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { SignatureMint1155 } from "typechain/SignatureMint1155";

// Types
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Tokens minted regularly by minter", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let accountWithoutMinterRole: SignerWithAddress;
  let nftReceiver: SignerWithAddress;

  // Contracts
  let sigMint1155: SignatureMint1155;

  // Default `mintTo` params
  const uri: string = "ipfs://.../";
  const tokenIdToMint: number = 0;
  const quantityToMint: number = 5;

  before(async () => {
    [protocolProvider, protocolAdmin, accountWithoutMinterRole, nftReceiver] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    sigMint1155 = contracts.sigMint1155;
  });

  describe("Revert cases", function () {
    it("Should revert if caller does not have minter role", async () => {
      await expect(sigMint1155.connect(accountWithoutMinterRole).mintTo(nftReceiver.address, uri, tokenIdToMint, quantityToMint)).to.be.revertedWith(
        "not minter.",
      );
    });
  });

  describe("Events", function () {
    it("Should emit TokenMinted with mint information", async () => {

      await expect(sigMint1155.connect(protocolAdmin).mintTo(nftReceiver.address, uri, tokenIdToMint, quantityToMint))
        .to.emit(sigMint1155, "TokenMinted")
        .withArgs(
          ...Object.values({
            mintedTo: nftReceiver.address,
            tokenIdMinted: tokenIdToMint,
            uri: uri,
            quantityMinted: quantityToMint
          }),
        );
    });
  });

  describe("Balances", function () {
    it("Should increase the NFT receiver's relevant balance by 1", async () => {
      const balBefore = await sigMint1155.balanceOf(nftReceiver.address, tokenIdToMint);
      await sigMint1155.connect(protocolAdmin).mintTo(nftReceiver.address, uri, tokenIdToMint, quantityToMint);
      const balAfter = await sigMint1155.balanceOf(nftReceiver.address, tokenIdToMint);

      expect(balAfter).to.equal(balBefore.add(quantityToMint));
    });
  });

  describe("Contract state", function () {

    it("Should store the relevant URI for the NFT", async () => {
      await sigMint1155.connect(protocolAdmin).mintTo(nftReceiver.address, uri, tokenIdToMint, quantityToMint);

      expect(await sigMint1155.tokenURI(tokenIdToMint)).to.equal(uri);
    });
  });
});
