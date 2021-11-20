// Test imports
import { ethers } from "hardhat";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
chai.use(solidity);

import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";

// Contract Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { Forwarder } from "../../typechain/Forwarder";
import { Registry } from "../../typechain/Registry";
import { ProtocolControl } from "../../typechain/ProtocolControl";
import { Coin } from "../../typechain/Coin";
import { Market } from "../../typechain/Market";
import { LazyNFT } from "../../typechain/LazyNFT";
import { MockLazyNFTReentrant } from "../../typechain/MockLazyNFTReentrant";

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

  let leaves: Array<any>;
  let tree: MerkleTree;
  let root: string;

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, creator, fan, stakeHolder1, stakeHolder2, stakeHolder3, relayer] = signers;

    // Get contract factory.
    LazyNFTFactory = await ethers.getContractFactory("LazyNFT");

    // merkle roots
    leaves = [creator.address, fan.address];
    tree = new MerkleTree(leaves, keccak256, { hashLeaves: true, sortPairs: true });
    root = tree.getHexRoot();
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

    it("mint batch and amount", async () => {
      await lazynft.lazyMintAmount(1);
      await lazynft.lazyMintBatch([uri_tokens[1]]);
      await lazynft.lazyMintAmount(1);
      expect(await lazynft.tokenURI(0)).equals("ipfs://baseuri/0");
      expect(await lazynft.tokenURI(1)).equals(uri_tokens[1]);
      expect(await lazynft.tokenURI(2)).equals("ipfs://baseuri/2");
      expect(await lazynft.nextTokenId()).equals(3);
    });
  });

  describe("mint conditions: max mint supply", function () {
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
    });

    it("max mint zero mint supply revert at 0", async () => {
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

  describe("mint conditions: start timestamp", function () {
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
  });

  describe("mint conditions: quantityLimitPerTransaction", function () {
    const proofs = [ethers.utils.hexZeroPad([0], 32)];
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
    });

    it("reverts when quantity limit is 0", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 1,
            currentMintSupply: 0,
            quantityLimitPerTransaction: 0,
            waitTimeSecondsLimitPerTransaction: 0,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.be.revertedWith("quantity limit cannot be 0");
    });

    it("unlimited buy per transactions", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: ethers.constants.MaxUint256,
            waitTimeSecondsLimitPerTransaction: 0,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(100, proofs)).to.be.not.reverted;
    });

    it("single buy per transactions", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: 1,
            waitTimeSecondsLimitPerTransaction: 0,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(2, proofs)).to.be.revertedWith("exceed tx limit");
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
    });
  });

  describe("mint conditions: wait time seconds per transactions", function () {
    const proofs = [ethers.utils.hexZeroPad([0], 32)];
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
    });

    it("multiple claims with no wait time", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: 1,
            waitTimeSecondsLimitPerTransaction: 0,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 60]);
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
    });

    it("multiple claims with wait time", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: ethers.constants.MaxUint256,
            waitTimeSecondsLimitPerTransaction: 60,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("cannot mint yet");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 60]);
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("cannot mint yet");
    });

    it("wait time overflow", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: ethers.constants.MaxUint256,
            waitTimeSecondsLimitPerTransaction: ethers.constants.MaxUint256,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("cannot mint yet");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 3600]);
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("cannot mint yet");
    });

    it("reset mint conditions should reset wait time", async () => {
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: ethers.constants.MaxUint256,
            waitTimeSecondsLimitPerTransaction: ethers.constants.MaxUint256,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("cannot mint yet");
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: ethers.constants.MaxUint256,
            waitTimeSecondsLimitPerTransaction: 0,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(
        lazynft.setPublicMintConditions([
          {
            startTimestamp: 0,
            maxMintSupply: 100,
            currentMintSupply: 0,
            quantityLimitPerTransaction: ethers.constants.MaxUint256,
            waitTimeSecondsLimitPerTransaction: ethers.constants.MaxUint256,
            pricePerToken: 0,
            currency: ethers.constants.AddressZero,
            merkleRoot: ethers.utils.hexZeroPad([0], 32),
          },
        ]),
      ).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.not.be.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("cannot mint yet");
    });
  });

  describe("mint conditions: price and currency", function () {
    const proofs = [ethers.utils.hexZeroPad([0], 32)];
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
    });

    it("claim 3 using native token", async () => {
      const price = ethers.utils.parseUnits("10", "ether");
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: price,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      const quantity = 3;
      await expect(
        await lazynft.connect(creator).claim(quantity, proofs, { value: price.mul(quantity) }),
      ).to.changeEtherBalances(
        [creator, lazynft, protocolControl],
        [price.mul(-1).mul(quantity), 0, price.mul(quantity)],
      );
    });

    it("claim with incorrect value (buying 3, paying for 1)", async () => {
      const price = ethers.utils.parseUnits("10", "ether");
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: price,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      const quantity = 3;
      await expect(lazynft.connect(creator).claim(quantity, proofs, { value: price })).to.be.revertedWith(
        "value != amount",
      );
    });

    it("claim 3 using erc20 token goes to treasury", async () => {
      const price = ethers.utils.parseUnits("10", "ether");
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: price,
          currency: coin.address,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      const quantity = 3;
      const totalPrice = price.mul(quantity);
      await expect(coin.mint(creator.address, totalPrice)).to.not.be.reverted;
      await expect(coin.connect(creator).approve(lazynft.address, totalPrice)).to.not.be.reverted;
      await expect(() => lazynft.connect(creator).claim(quantity, proofs)).to.changeTokenBalances(
        coin,
        [creator, lazynft, protocolControl],
        [price.mul(-1).mul(quantity), 0, price.mul(quantity)],
      );
    });
  });

  describe("sale: primary sale payout", function () {
    const proofs = [ethers.utils.hexZeroPad([0], 32)];
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);

      await lazynft.setSaleRecipient(stakeHolder3.address);
    });

    it("claim 3 using native token with no fees", async () => {
      const price = ethers.utils.parseUnits("10", "ether");
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: price,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      const quantity = 3;
      await expect(
        await lazynft.connect(creator).claim(quantity, proofs, { value: price.mul(quantity) }),
      ).to.changeEtherBalances(
        [creator, lazynft, protocolControl, stakeHolder3],
        [price.mul(-1).mul(quantity), 0, 0, price.mul(quantity)],
      );
    });

    it("claim 3 using erc20 token with no fees", async () => {
      const price = ethers.utils.parseUnits("10", "ether");
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: price,
          currency: coin.address,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      const quantity = 3;
      const totalPrice = price.mul(quantity);
      await expect(coin.mint(creator.address, totalPrice)).to.not.be.reverted;
      await expect(coin.connect(creator).approve(lazynft.address, totalPrice)).to.not.be.reverted;
      await expect(() => lazynft.connect(creator).claim(quantity, proofs)).to.changeTokenBalances(
        coin,
        [creator, lazynft, protocolControl, stakeHolder3],
        [price.mul(-1).mul(quantity), 0, 0, price.mul(quantity)],
      );
    });
  });

  describe("sale: fees", function () {
    const proofs = [ethers.utils.hexZeroPad([0], 32)];
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);

      await lazynft.setFeeBps(1000); // 10%
      await lazynft.setSaleRecipient(stakeHolder3.address);
    });

    it("claim 3 using native token with 10% fees to protocol", async () => {
      const price = ethers.utils.parseUnits("10", "ether");
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: price,
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      const quantity = 3;
      const totalPrice = price.mul(quantity);
      const fee = totalPrice.mul(BigNumber.from(1000)).div(BigNumber.from(MAX_BPS));
      await expect(
        await lazynft.connect(creator).claim(quantity, proofs, { value: price.mul(quantity) }),
      ).to.changeEtherBalances(
        [creator, lazynft, protocolControl, stakeHolder3],
        [totalPrice.mul(-1), 0, fee, totalPrice.sub(fee)],
      );
    });

    it("claim 3 using erc20 token with 10% fees to protocol", async () => {
      const price = ethers.utils.parseUnits("10", "ether");
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: price,
          currency: coin.address,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);
      const quantity = 3;
      const totalPrice = price.mul(quantity);
      const fee = totalPrice.mul(BigNumber.from(1000)).div(BigNumber.from(MAX_BPS));
      await expect(coin.mint(creator.address, totalPrice)).to.not.be.reverted;
      await expect(coin.connect(creator).approve(lazynft.address, totalPrice)).to.not.be.reverted;
      await expect(() => lazynft.connect(creator).claim(quantity, proofs)).to.changeTokenBalances(
        coin,
        [creator, lazynft, protocolControl, stakeHolder3],
        [price.mul(-1).mul(quantity), 0, fee, price.mul(quantity).sub(fee)],
      );
    });
  });

  describe("mint conditions: merkle roots", function () {
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: ethers.constants.MaxUint256,
          currentMintSupply: 0,
          quantityLimitPerTransaction: ethers.constants.MaxUint256,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: 0,
          currency: ethers.constants.AddressZero,
          merkleRoot: root,
        },
      ]);
    });

    it("claim with correct proofs", async () => {
      const proofs: BytesLike[] = tree.getHexProof(keccak256(creator.address));
      await expect(lazynft.connect(creator).claim(1, proofs)).to.be.not.reverted;
    });

    it("claim with someone else proofs", async () => {
      const proofs1: BytesLike[] = tree.getHexProof(keccak256(stakeHolder1.address));
      await expect(lazynft.connect(creator).claim(1, proofs1)).to.be.revertedWith("invalid proofs");
      const proofs2: BytesLike[] = tree.getHexProof(keccak256(fan.address));
      await expect(lazynft.connect(creator).claim(1, proofs2)).to.be.revertedWith("invalid proofs");
    });

    it("claim with not included proofs", async () => {
      const proofs: BytesLike[] = tree.getHexProof(keccak256(stakeHolder1.address));
      await expect(lazynft.connect(stakeHolder1).claim(1, proofs)).to.be.revertedWith("invalid proofs");
    });
  });

  describe("mint conditions: multi stages", function () {
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(100);
      await lazynft.lazyMintAmount(100);
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
    });

    it("changes active condition index", async () => {
      await expect(lazynft.getLastStartedMintConditionIndex()).to.be.revertedWith("no active mint condition");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      expect(await lazynft.getLastStartedMintConditionIndex()).to.be.equal(0);
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      expect(await lazynft.getLastStartedMintConditionIndex()).to.be.equal(1);
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      expect(await lazynft.getLastStartedMintConditionIndex()).to.be.equal(2);
    });

    it("stays at the last index", async () => {
      await expect(lazynft.getLastStartedMintConditionIndex()).to.be.revertedWith("no active mint condition");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      expect(await lazynft.getLastStartedMintConditionIndex()).to.be.equal(0);
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 420420]);
      expect(await lazynft.getLastStartedMintConditionIndex()).to.be.equal(2);
    });

    it("multiple stage start timestamp", async () => {
      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("no active mint condition");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      await expect(lazynft.claim(1, proofs)).to.be.not.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("exceed max mint supply");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      await expect(lazynft.claim(2, proofs)).to.be.not.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("exceed max mint supply");
      await ethers.provider.send("evm_mine", [(await ethers.provider.getBlock("latest")).timestamp + 120]);
      await expect(lazynft.claim(3, proofs)).to.be.not.reverted;
      await expect(lazynft.claim(1, proofs)).to.be.revertedWith("exceed max mint supply");
    });
  });

  let mockLazy: MockLazyNFTReentrant;
  describe("re-entrancy tests", function () {
    beforeEach(async () => {
      await lazynft.setMaxTotalSupply(101);
      await lazynft.lazyMintAmount(100);

      mockLazy = await (await ethers.getContractFactory("MockLazyNFTReentrant")).deploy(lazynft.address);

      await protocolAdmin.sendTransaction({
        to: mockLazy.address,
        value: ethers.utils.parseUnits("15", "ether"),
      });
    });

    it("reentrant on onERC721Received no limit", async () => {
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: 100,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: ethers.utils.parseUnits("1", "ether"),
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);

      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await expect(mockLazy.attack()).to.be.revertedWith("ReentrancyGuard: reentrant call");
    });

    it("reentrant on receive (malicious sale recipient): max mint supply", async () => {
      await lazynft.setSaleRecipient(mockLazy.address);
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: 1,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: ethers.utils.parseUnits("1", "ether"),
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);

      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await expect(mockLazy.setAttackOnReceive(true)).to.not.be.reverted;
      await expect(mockLazy.attack()).to.be.revertedWith("Address: unable to send value, recipient may have reverted");
    });

    it("reentrant on receive (malicious sale recipient): quantity limit per tx", async () => {
      await lazynft.setSaleRecipient(mockLazy.address);
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: 10000,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 1,
          waitTimeSecondsLimitPerTransaction: 0,
          pricePerToken: ethers.utils.parseUnits("1", "ether"),
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);

      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await expect(mockLazy.setAttackOnReceive(true)).to.not.be.reverted;
      await expect(mockLazy.attack()).to.be.revertedWith("Address: unable to send value, recipient may have reverted");
    });

    it("reentrant on receive (malicious sale recipient): wait time seconds", async () => {
      await lazynft.setSaleRecipient(mockLazy.address);
      await lazynft.setPublicMintConditions([
        {
          startTimestamp: 0,
          maxMintSupply: 10000,
          currentMintSupply: 0,
          quantityLimitPerTransaction: 10000,
          waitTimeSecondsLimitPerTransaction: 3600,
          pricePerToken: ethers.utils.parseUnits("1", "ether"),
          currency: ethers.constants.AddressZero,
          merkleRoot: ethers.utils.hexZeroPad([0], 32),
        },
      ]);

      const proofs = [ethers.utils.hexZeroPad([0], 32)];
      await expect(mockLazy.setAttackOnReceive(true)).to.not.be.reverted;
      await expect(mockLazy.attack()).to.be.revertedWith("Address: unable to send value, recipient may have reverted");
    });
  });
});
