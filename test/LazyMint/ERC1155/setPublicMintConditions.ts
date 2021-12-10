import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC1155, MintConditionStruct } from "typechain/LazyMintERC1155";

// Types
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";
// const { MerkleTree } = require('merkletreejs')
// const keccak256 = require("keccak256");

use(solidity);

describe("Test: set public mint conditions", function() {

  // Constants
  const NATIVE_TOKEN_ADDRESS: string = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
    
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;

  // Contracts
  let lazyMintERC1155: LazyMintERC1155;

  // Lazy minting params
  const amountToLazyMint: BigNumber = BigNumber.from(10_000);
  const baseURI: string = "ipfs://baseURI/";

  // Setting mint conditions default params
  const tokenId: BigNumber = BigNumber.from(0);
  let mintConditions: MintConditionStruct[];

  before(async () => {
    [protocolProvider, protocolAdmin] = await ethers.getSigners()
  })

  beforeEach(async () => {  
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    lazyMintERC1155 = contracts.lazyMintERC1155;

    // Lazy mint tokens
    await lazyMintERC1155.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI);

    // Set mint conditions
    const templateMintCondition: MintConditionStruct = {
      
      startTimestamp: BigNumber.from(
          (await ethers.provider.getBlock("latest")).timestamp
        ).add(100),
      maxMintSupply: BigNumber.from(100),
      currentMintSupply: BigNumber.from(0),
      quantityLimitPerTransaction: BigNumber.from(5),
      waitTimeInSecondsBetweenClaims: BigNumber.from(100),
      merkleRoot: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test")),
      pricePerToken: ethers.utils.parseEther("0.1"),
      currency: NATIVE_TOKEN_ADDRESS
    }

    mintConditions = [...Array(5).keys()]
      .map((val: number) => val * 100)
      .map((val: number) => {
        return {
          ...templateMintCondition,
          startTimestamp: (templateMintCondition.startTimestamp as BigNumber).add(val)
        }
      })
  })

  describe("Revert cases", function() {
    
    it("Should revert if mint conditions are not in ascending order by timestamp", async () => {
      const temp: MintConditionStruct = mintConditions[0];
      mintConditions[0] = mintConditions[mintConditions.length - 1]
      mintConditions[mintConditions.length - 1] = temp;

      await expect(
        lazyMintERC1155.connect(protocolAdmin).setPublicMintConditions(tokenId, mintConditions)
      ).to.be.revertedWith("LazyMintERC1155: startTimestamp must be in ascending order")
    })
    
    it("Should revert if max mint supply is zero", async () => {
      mintConditions[0].maxMintSupply = 0;

      await expect(
        lazyMintERC1155.connect(protocolAdmin).setPublicMintConditions(tokenId, mintConditions)
      ).to.be.revertedWith("LazyMintERC1155: max mint supply cannot be 0")
    })

    it("Should revert if quantity limit per claim transaction is zero", async () => {
      mintConditions[0].quantityLimitPerTransaction = 0;

      await expect(
        lazyMintERC1155.connect(protocolAdmin).setPublicMintConditions(tokenId, mintConditions)
      ).to.be.revertedWith("LazyMintERC1155: quantity limit cannot be 0")
    })
  })

  describe("Events", function() {
    it("Should emit NewMintConditions", async () => {

      await expect(
        lazyMintERC1155.connect(protocolAdmin).setPublicMintConditions(tokenId, mintConditions)
      ).to.emit(lazyMintERC1155, "NewMintConditions")      
    })
  })

  describe("Contract state", function() {
    
    it("Should increment the condition index to use for future mint conditions", async () => {
      const indexBefore: BigNumber = await lazyMintERC1155.mintConditions(tokenId) // returns `nextConditionIndex` from `PublicMintConditions`
      await lazyMintERC1155.connect(protocolAdmin).setPublicMintConditions(tokenId, mintConditions)
      const indexAfter: BigNumber = await lazyMintERC1155.mintConditions(tokenId) // returns `nextConditionIndex` from `PublicMintConditions`

      expect(indexAfter).to.equal(indexBefore.add(mintConditions.length));
    })
    
    it("Should store each mint condition at the right index", async () => {
      const indexBefore: BigNumber = await lazyMintERC1155.mintConditions(tokenId) // returns `nextConditionIndex` from `PublicMintConditions`
      await lazyMintERC1155.connect(protocolAdmin).setPublicMintConditions(tokenId, mintConditions);
      const nextIndex: BigNumber = await lazyMintERC1155.mintConditions(tokenId) // returns `nextConditionIndex` from `PublicMintConditions`

      for(let i = indexBefore.toNumber(); i < nextIndex.toNumber(); i += 1) {
        
        const condition: MintConditionStruct = await lazyMintERC1155.getMintConditionAtIndex(tokenId, i);
        
        expect(condition.startTimestamp).to.equal(mintConditions[i].startTimestamp)
        expect(condition.maxMintSupply).to.equal(mintConditions[i].maxMintSupply)
        expect(condition.currentMintSupply).to.equal(mintConditions[i].currentMintSupply)
        expect(condition.quantityLimitPerTransaction).to.equal(mintConditions[i].quantityLimitPerTransaction)
        expect(condition.waitTimeInSecondsBetweenClaims).to.equal(mintConditions[i].waitTimeInSecondsBetweenClaims)
        expect(condition.merkleRoot).to.equal(mintConditions[i].merkleRoot)
        expect(condition.pricePerToken).to.equal(mintConditions[i].pricePerToken)
        expect(condition.currency).to.equal(mintConditions[i].currency)
      }
    })
  })
})