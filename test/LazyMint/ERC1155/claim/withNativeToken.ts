import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC1155, MintConditionStruct } from "typechain/LazyMintERC1155";

// Types
import { BigNumber, BytesLike } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../../utils/tests/getContracts";
const { MerkleTree } = require('merkletreejs')
const keccak256 = require("keccak256");

use(solidity);

describe("Test: lazy mint tokens", function() {
  // Constants
  const NATIVE_TOKEN_ADDRESS: string = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
    
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let claimer: SignerWithAddress;

  // Contracts
  let lazyMintERC1155: LazyMintERC1155;

  // Lazy minting params
  const amountToLazyMint: BigNumber = BigNumber.from(10_000);
  const baseURI: string = "ipfs://baseURI/";

  // Setting mint conditions default params
  const tokenId: BigNumber = BigNumber.from(0);
  let mintConditions: MintConditionStruct[];

  // Claim params
  let proof: BytesLike[];
  let quantityToClaim: BigNumber;

  before(async () => {
    [protocolProvider, protocolAdmin, claimer] = await ethers.getSigners()
  })

  beforeEach(async () => {  
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    lazyMintERC1155 = contracts.lazyMintERC1155;

    // Lazy mint tokens
    await lazyMintERC1155.connect(protocolAdmin).lazyMint(amountToLazyMint, baseURI);

    // Generate a merkle root for whitelisting
    const leaves = [claimer.address].map(x => keccak256(x));
    const tree = new MerkleTree(leaves, keccak256);
    const whitelist = tree.getRoot().toString('hex');    

    // Set mint conditions
    const templateMintCondition: MintConditionStruct = {
      
      startTimestamp: BigNumber.from(
          (await ethers.provider.getBlock("latest")).timestamp
        ).add(100),
      maxMintSupply: BigNumber.from(100),
      currentMintSupply: BigNumber.from(0),
      quantityLimitPerTransaction: BigNumber.from(5),
      waitTimeInSecondsBetweenClaims: BigNumber.from(100),
      merkleRoot: whitelist,
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
    
    // Set claim params
    proof = tree.getProof(claimer.address);
    quantityToClaim = BigNumber.from(mintConditions[0].quantityLimitPerTransaction);
  })

  describe("Revert cases", function() {
    it("Should revert if quantity wanted is zero")
    it("Should revert if quantity wanted is greater than limit per transaction")
    it("Should revert if quantity wanted + current mint supply exceeds max mint supply")
    it("Should revert if claimer claims before valid timestamp for transaction")
    it("Should revert if claimer is not in the whitelist")
  })
  
  describe("Events")
  describe("Balances")
  describe("Contract state")
})