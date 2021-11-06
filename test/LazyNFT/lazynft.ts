// Test imports
import { ethers } from "hardhat";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
chai.use(solidity);

// Contract Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { Forwarder } from "../../typechain/Forwarder";
import { Registry } from "../../typechain/Registry";
import { ProtocolControl } from "../../typechain/ProtocolControl";
import { Coin } from "../../typechain/Coin";
import { Market } from "../../typechain/Market";
import { LazyNFT } from "../../typechain/LazyNFT";

// Types
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, BigNumberish } from "ethers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts, getAmountBounded, getBoundedEtherAmount } from "../../utils/tests/params";

describe("LazyNFT", function () {
  const MAX_BPS = 10000;
  const SCALE_FACTOR = 10000;
  const defaultFeeBps = 500; // 5%

  let LazyNFTFactory: any;
  let feeTreasury = "";
  let feeBps = -1;

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let fan: SignerWithAddress;
  let stakeHolder1: SignerWithAddress;
  let stakeHolder2: SignerWithAddress;
  let stakeHolder3: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let forwarder: Forwarder;
  let registry: Registry;
  let protocolControl: ProtocolControl;
  let market: Market;
  let accessNft: AccessNFT;
  let coin: Coin;
  let lazynft: LazyNFT;

  // Reward parameters
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getAmounts(rewardURIs.length);
  const emptyData: BytesLike = ethers.utils.toUtf8Bytes("");

  // Market parameters
  const price: BigNumber = getBoundedEtherAmount();
  const amountOfTokenToList = getAmountBounded(rewardSupplies[0]);
  const tokensPerBuyer = getAmountBounded(parseInt(amountOfTokenToList.toString()));
  const openStartAndEnd: number = 0;
  const rewardId: number = 1;
  const listingId: number = 0;
  const amountToBuy: number = 1;

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, creator, fan, stakeHolder1, stakeHolder2, stakeHolder3, relayer] = signers;

    // Get contract factory.
    LazyNFTFactory = await ethers.getContractFactory("LazyNFT");
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);
    registry = contracts.registry;
    protocolControl = contracts.protocolControl;
    forwarder = contracts.forwarder;
    market = contracts.market;
    accessNft = contracts.accessNft;
    coin = contracts.coin;
    lazynft = contracts.lazynft;

    feeBps = (await registry.getFeeBps(protocolControl.address)).toNumber();
    feeTreasury = await registry.treasury();
  });

  describe("Mint States", function () {
    const uri_tokens = ["ipfs://token_1", "ipfs://token_2"];

    it("mint single", async () => {
      await lazynft.lazyMintBatch(uri_tokens);
      expect(await lazynft.tokenURI(0)).equals(uri_tokens[0]);
      expect(await lazynft.tokenURI(1)).equals(uri_tokens[1]);
      expect(await lazynft.nextTokenId()).equals(2);
    });

    it("mint batch", async () => {
      await lazynft.lazyMintBatch(uri_tokens);
      expect(await lazynft.tokenURI(0)).equals(uri_tokens[0]);
      expect(await lazynft.tokenURI(1)).equals(uri_tokens[1]);
      expect(await lazynft.nextTokenId()).equals(2);
    });

    it("mint amount", async () => {
      await lazynft.lazyMintAmount(3);
      expect(await lazynft.tokenURI(0)).equals("ipfs://baseuri/0");
      expect(await lazynft.tokenURI(1)).equals("ipfs://baseuri/1");
      expect(await lazynft.tokenURI(2)).equals("ipfs://baseuri/2");
      expect(await lazynft.nextTokenId()).equals(3);
    });

    it("mint single and amount", async () => {
      await lazynft.lazyMintAmount(1);
      await lazynft.lazyMintBatch([uri_tokens[1]]);
      await lazynft.lazyMintAmount(1);
      expect(await lazynft.tokenURI(0)).equals("ipfs://baseuri/0");
      expect(await lazynft.tokenURI(1)).equals(uri_tokens[1]);
      expect(await lazynft.tokenURI(2)).equals("ipfs://baseuri/2");
      expect(await lazynft.nextTokenId()).equals(3);
    });
  });

  describe("mint conditions: max supply", function () {
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
    });

    it("max mint supply", async () => {
      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: 100,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      expect(await lazynft.nextTokenId()).equals(100);
      expect(await lazynft.nextMintTokenId()).equals(0);
      expect(await lazynft.claim(100, proofs));
      expect(await lazynft.nextTokenId()).equals(100);
      expect(await lazynft.nextMintTokenId()).equals(100);
    });

    it("max mint exceed mint supply revert", async () => {
      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: 100,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      expect(await lazynft.claim(100, proofs));
      await expect(lazynft.claim(1, proofs)).to.be.reverted;
    });

    it("max mint zero mint supply revert", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 0,
            currentMintSupply: 0,
            quantityLimitPerTransaction: 10000,
            waitTimeSecondsLimitPerTransaction: 0,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.be.reverted;
    });

    it("max mint supply more than total supply", async () => {
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
    });
  });

  describe("mint conditions: start time", function () {
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
    });

    it("single stage start timestamp", async () => {
      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 120,
          maxMintSupply: 100,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      await expect(lazynft.claim(1, proofs)).to.be.reverted;
      const now = (await ethers.provider.getBlock("latest")).timestamp;
      await ethers.provider.send("evm_mine", [now + 120]);
      await expect(lazynft.claim(1, proofs)).to.be.not.reverted;
    });

    it("multiple stage start timestamp", async () => {
      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 120,
          maxMintSupply: 1,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
        {
          startTimestamp: 240,
          maxMintSupply: 2,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
        {
          startTimestamp: 360,
          maxMintSupply: 3,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("NFT: no active mint condition");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      await expect(lazynft.claim(1, proofs)).to.be.not.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("NFT: exceeding max mint supply");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      await expect(lazynft.claim(2, proofs)).to.be.not.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("NFT: exceeding max mint supply");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      await expect(lazynft.claim(3, proofs)).to.be.not.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("NFT: exceeding max mint supply");
    });
  });
});
