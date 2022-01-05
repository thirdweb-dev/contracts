import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { SignatureMint721 } from "typechain/SignatureMint721";

// Types
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Mint tokens with a valid mint request", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let accountWithoutMinterRole: SignerWithAddress;
  let nftReceiver: SignerWithAddress;

  // Contracts
  let sigMint721: SignatureMint721;

  // Default `mintTo` params
  const uri: string = "ipfs://.../"

  before(async () => {
    [protocolProvider, protocolAdmin, accountWithoutMinterRole, nftReceiver] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    sigMint721 = contracts.sigMint721;
  });

  describe("Revert cases", function() {
    it("Should revert if caller does not have minter role", async () => {
      await expect(
        sigMint721.connect(accountWithoutMinterRole).mintTo(nftReceiver.address, uri)
      ).to.be.revertedWith("not minter.")
    })
  })
  
  describe("Events", function() {
    it("Should emit TokensMintedByMinter with mint information", async () => {
      
      const tokenIdToBeMinted = await sigMint721.nextTokenIdToMint();
      
      await expect(
        sigMint721.connect(protocolAdmin).mintTo(nftReceiver.address, uri)
      ).to.emit(sigMint721, "TokensMintedByMinter")
      .withArgs(
        ...Object.values({
          minter: protocolAdmin.address,
          mintedTo: nftReceiver.address,
          tokenIdMinted: tokenIdToBeMinted,
          uri: uri
        })
      )
    })
  })

  describe("Balances", function() {
    it("Should increase the NFT receiver's relevant balance by 1", async () => {
      const balBefore = await sigMint721.balanceOf(nftReceiver.address);
      await sigMint721.connect(protocolAdmin).mintTo(nftReceiver.address, uri)
      const balAfter = await sigMint721.balanceOf(nftReceiver.address);

      expect(balAfter).to.equal(balBefore.add(1));
    })
  })

  describe("Contract state", function() {
    it("Should increment the next tokenId to mint by 1", async () => {
      const nextIdToMintBefore = await sigMint721.nextTokenIdToMint();
      await sigMint721.connect(protocolAdmin).mintTo(nftReceiver.address, uri)
      const nextIdToMintAfter = await sigMint721.nextTokenIdToMint();

      expect(nextIdToMintAfter).to.equal(nextIdToMintBefore.add(1));
    })

    it("Should store the relevant URI for the NFT", async () => {
      const tokenIdToCheck = await sigMint721.nextTokenIdToMint();
      await sigMint721.connect(protocolAdmin).mintTo(nftReceiver.address, uri)

      expect(await sigMint721.tokenURI(tokenIdToCheck)).to.equal(uri);
    })
  })
});
