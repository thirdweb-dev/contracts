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
import { Royalty } from "../../typechain/Royalty";

// Types
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, BigNumberish } from "ethers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts, getAmountBounded, getBoundedEtherAmount } from "../../utils/tests/params";
import { sendGaslessTx } from "../../utils/tests/gasless";

describe("Royalty", function () {
  const MAX_BPS = 10000;
  const SCALE_FACTOR = 10000;
  const defaultFeeBps = 500; // 5%

  let RoyaltyFactory: any;
  let deployRoyalty: any;
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

  // Test parameters
  const singlePayee: string = "0x000000000000000000000000000000000000dEaD";
  const multiplePayees: string[] = [
    "0x000000000000000000000000000000000000dEaD",
    "0x00000000000000000000000000000000dEadDEaD",
    "0x0000000000000000000000000000deadDEaDdeAd",
  ];

  // Network
  const payeeAddedInterface = new ethers.utils.Interface(["event PayeeAdded(address account, uint256 shares)"]);

  before(async () => {
    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolProvider, protocolAdmin, creator, fan, stakeHolder1, stakeHolder2, stakeHolder3, relayer] = signers;

    // Get contract factory.
    RoyaltyFactory = await ethers.getContractFactory("Royalty");
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

    feeBps = (await registry.getFeeBps(protocolControl.address)).toNumber();
    feeTreasury = await registry.treasury();

    deployRoyalty = async (payees: string[], shares: BigNumberish[]): Promise<Royalty> =>
      (await RoyaltyFactory.deploy(registry.address, forwarder.address, "", payees, shares)) as Royalty;
  });

  describe("Default state of fees", function () {
    it("Should initially return default fee bps and treasury", async () => {
      expect(feeBps).to.be.equals(defaultFeeBps);
      expect(feeTreasury).to.be.equals(protocolProvider.address);
    });
  });

  describe("Default state of Royalty contract", function () {
    it("Emits, for each payee, PayeeAdded with payee address and shares on creation", async () => {
      // Set payes and shares
      const payees = [singlePayee];
      const shares = [1];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);
      const receipt = await royaltyContract.deployTransaction.wait();

      // Get PayeeAdded events emitted.
      const payeeAdded = receipt.logs
        .map((l: any) => {
          try {
            return payeeAddedInterface.parseLog(l);
          } catch (e) {
            return "";
          }
        })
        .filter(e => !!e)
        .map((l: any) => l.args);

      expect(payeeAdded.length).to.be.equals(payees.length + 1); // All payess + registry treasury.
      expect(payeeAdded[0].account).to.be.equals(payees[0]);
      expect(payeeAdded[1].account).to.be.equals(feeTreasury);

      const scaledShares = shares[0] * SCALE_FACTOR;
      const scaledSharesFees = (scaledShares * feeBps) / MAX_BPS;
      const scaledSharesMinusFee = scaledShares - scaledSharesFees;

      expect(payeeAdded[0].shares.toNumber()).to.be.equals(scaledSharesMinusFee);
      expect(payeeAdded[1].shares.toNumber()).to.be.equals(scaledSharesFees);
    });

    it("Should store the right shares on the contract", async () => {
      const payees = multiplePayees;
      const shares = [1, 2, 3];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(await royaltyContract.totalShares()).to.be.equals((1 + 2 + 3) * SCALE_FACTOR);

      let totalFees = 0;
      for (let i = 0; i < payees.length; i++) {
        // Get share split
        const scaledShares = shares[i] * SCALE_FACTOR;
        const scaledSharesFees = (scaledShares * feeBps) / MAX_BPS;
        const scaledSharesMinusFee = scaledShares - scaledSharesFees;

        // Update fees
        totalFees += scaledSharesFees;

        // Check shares for payees;
        expect((await royaltyContract.shares(payees[i])).toNumber()).to.be.equals(scaledSharesMinusFee);
      }

      // Check shares for protocol provider i.e. at this point, registry treasury.
      expect((await royaltyContract.shares(feeTreasury)).toNumber()).to.be.equals(totalFees);
    });
  });

  describe("Set Protocol Control Treasury", function () {
    it("Should allow setting a valid Royalty contract", async () => {
      // Set payes and shares
      const payees = multiplePayees;
      const shares = [1, 2, 3];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be
        .reverted;
    });

    it("Should revert if setting an invalid Royalty contract", async () => {
      // Set payes and shares
      const payees = multiplePayees;
      const shares = [1, 2, 3];

      const invalidRoyaltyContract = await ethers
        .getContractFactory("MockRoyaltyNoFees")
        .then(f => f.connect(protocolAdmin).deploy(protocolControl.address, forwarder.address, "", payees, shares));

      expect(invalidRoyaltyContract.address).to.not.be.empty;

      await expect(
        protocolControl.connect(protocolAdmin).setRoyaltyTreasury(invalidRoyaltyContract.address),
      ).to.be.revertedWith("ProtocolControl: provider shares too low.");
    });
  });

  describe("Fees", function () {
    it("Correct payouts (50, 50)", async () => {
      const treasury = protocolProvider;
      const feeBps = await registry.getFeeBps(protocolControl.address);
      const payees = [stakeHolder1.address, stakeHolder2.address];
      const shares = [50, 50];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be
        .reverted;

      const price = ethers.utils.parseUnits("1000", "ether");
      await expect(
        await protocolAdmin.sendTransaction({
          to: royaltyContract.address,
          value: price,
        }),
      ).to.changeEtherBalance(royaltyContract, price);

      // console.log("feeBps", feeBps.toString());

      await expect(await royaltyContract["release(address)"](stakeHolder1.address)).to.changeEtherBalances(
        [royaltyContract, stakeHolder1],
        [
          // 500 because 50% of 1000
          ethers.utils.parseUnits("-500", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("500", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
        ],
      );

      await expect(await royaltyContract["release(address)"](stakeHolder2.address)).to.changeEtherBalances(
        [royaltyContract, stakeHolder2],
        [
          // 500 because 50% of 1000
          ethers.utils.parseUnits("-500", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("500", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
        ],
      );

      await expect(await royaltyContract["release(address)"](treasury.address)).to.changeEtherBalances(
        [royaltyContract, treasury],
        [
          // 50 because 5% of 1000
          ethers.utils.parseUnits("-50", "ether"),
          ethers.utils.parseUnits("50", "ether"),
        ],
      );
    });

    it("Correct payouts (25, 75)", async () => {
      const treasury = protocolProvider;
      const feeBps = await registry.getFeeBps(protocolControl.address);
      const payees = [stakeHolder1.address, stakeHolder2.address];
      const shares = [25, 75];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be
        .reverted;

      const price = ethers.utils.parseUnits("1000", "ether");
      await expect(
        await protocolAdmin.sendTransaction({
          to: royaltyContract.address,
          value: price,
        }),
      ).to.changeEtherBalance(royaltyContract, price);

      // console.log("feeBps", feeBps.toString());

      await expect(await royaltyContract["release(address)"](stakeHolder1.address)).to.changeEtherBalances(
        [royaltyContract, stakeHolder1],
        [
          // 500 because 50% of 1000
          ethers.utils.parseUnits("-250", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("250", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
        ],
      );

      await expect(await royaltyContract["release(address)"](stakeHolder2.address)).to.changeEtherBalances(
        [royaltyContract, stakeHolder2],
        [
          // 500 because 50% of 1000
          ethers.utils.parseUnits("-750", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("750", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
        ],
      );

      await expect(await royaltyContract["release(address)"](treasury.address)).to.changeEtherBalances(
        [royaltyContract, treasury],
        [
          // 50 because 5% of 1000
          ethers.utils.parseUnits("-50", "ether"),
          ethers.utils.parseUnits("50", "ether"),
        ],
      );
    });
  });

  describe("Distribute to all payees", function () {
    it("distribute native", async () => {
      const treasury = protocolProvider;
      const feeBps = await registry.getFeeBps(protocolControl.address);
      const payees = [stakeHolder1.address, stakeHolder2.address];
      const shares = [25, 75];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be
        .reverted;

      const price = ethers.utils.parseUnits("1000", "ether");
      await expect(
        await protocolAdmin.sendTransaction({
          to: royaltyContract.address,
          value: price,
        }),
      ).to.changeEtherBalance(royaltyContract, price);

      await expect(await royaltyContract["distribute()"]()).to.changeEtherBalances(
        [royaltyContract, stakeHolder1, stakeHolder2, protocolProvider],
        [
          // 500 because 50% of 1000
          ethers.utils.parseUnits("-1000", "ether"),
          ethers.utils.parseUnits("250", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("750", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("50", "ether"),
        ],
      );
    });

    it("distribute erc20", async () => {
      const treasury = protocolProvider;
      const feeBps = await registry.getFeeBps(protocolControl.address);
      const payees = [stakeHolder1.address, stakeHolder2.address];
      const shares = [25, 75];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be
        .reverted;

      const price = ethers.utils.parseUnits("1000", "ether");
      await expect(() => coin.connect(protocolAdmin).mint(royaltyContract.address, price)).to.changeTokenBalance(
        coin,
        royaltyContract,
        price,
      );

      await expect(() => royaltyContract["distribute(address)"](coin.address)).to.changeTokenBalances(
        coin,
        [royaltyContract, stakeHolder1, stakeHolder2, protocolProvider],
        [
          // 500 because 50% of 1000
          ethers.utils.parseUnits("-1000", "ether"),
          ethers.utils.parseUnits("250", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("750", "ether").mul(BigNumber.from(MAX_BPS).sub(feeBps)).div(MAX_BPS),
          ethers.utils.parseUnits("50", "ether"),
        ],
      );
    });
  });

  describe("Reentrancy", function () {
    it("reentrance on release(address)", async () => {
      const mrr = await ethers.getContractFactory("MockRoyaltyReentrantDistribute");
      const mr = await mrr.deploy();

      const treasury = protocolProvider;
      const feeBps = await registry.getFeeBps(protocolControl.address);
      const payees = [mr.address, stakeHolder1.address];
      const shares = [50, 50];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(mr.address).to.not.be.empty;
      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be
        .reverted;

      await expect(mr.set(royaltyContract.address)).to.not.be.reverted;

      // account is not due because, the contract call distribute again
      await expect(royaltyContract["release(address)"](mr.address)).to.be.revertedWith(
        "PaymentSplitter: account is not due payment",
      );
    });
    it("reentrance on distribute", async () => {
      const mrr = await ethers.getContractFactory("MockRoyaltyReentrantDistribute");
      const mr = await mrr.deploy();

      const treasury = protocolProvider;
      const feeBps = await registry.getFeeBps(protocolControl.address);
      const payees = [mr.address, stakeHolder1.address];
      const shares = [50, 50];

      // Deploy Royalty
      const royaltyContract: Royalty = await deployRoyalty(payees, shares);

      expect(mr.address).to.not.be.empty;
      expect(royaltyContract.address).to.not.be.empty;
      await expect(protocolControl.connect(protocolAdmin).setRoyaltyTreasury(royaltyContract.address)).to.not.be
        .reverted;

      await expect(mr.set(royaltyContract.address)).to.not.be.reverted;

      // account is not due because, the contract call distribute again
      await expect(royaltyContract["distribute()"]()).to.be.revertedWith("PaymentSplitter: account is not due payment");
    });
  });

  describe("Test payouts on sale in Market", function () {
    // Royalty params
    let royaltyContract: Royalty;
    let payees: string[];
    let shares: number[];

    beforeEach(async () => {
      // Grant Minter role to creator
      const MINTER_ROLE = await accessNft.MINTER_ROLE();
      await accessNft.connect(protocolAdmin).grantRole(MINTER_ROLE, creator.address);

      // Create access packs
      await sendGaslessTx(creator, forwarder, relayer, {
        from: creator.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("createAccessTokens", [
          creator.address,
          rewardURIs,
          accessURIs,
          rewardSupplies,
          emptyData,
        ]),
      });

      // Approve Market to transfer tokens
      await sendGaslessTx(creator, forwarder, relayer, {
        from: creator.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("setApprovalForAll", [market.address, true]),
      });

      // List it on the market
      await sendGaslessTx(creator, forwarder, relayer, {
        from: creator.address,
        to: market.address,
        data: market.interface.encodeFunctionData("list", [
          accessNft.address,
          rewardId,
          coin.address,
          price,
          amountOfTokenToList,
          tokensPerBuyer,
          openStartAndEnd,
          openStartAndEnd,
        ]),
      });

      // Set 5% royalty on Access NFT
      await accessNft.connect(protocolAdmin).setRoyaltyBps(500);
      // Set 5% market fee
      await market.connect(protocolAdmin).setMarketFeeBps(500);

      // Deploy Royalty contract
      payees = [stakeHolder1.address, stakeHolder2.address, stakeHolder3.address];
      shares = [1, 2, 3];
      royaltyContract = (await RoyaltyFactory.deploy(
        registry.address,
        forwarder.address,
        "",
        payees,
        shares,
      )) as Royalty;

      // Set Royalty contract
      await accessNft.connect(protocolAdmin).setRoyaltyRecipient(royaltyContract.address);
      await market.connect(protocolAdmin).setMarketFeeRecipient(royaltyContract.address);

      // Mint currency to fan
      await coin.connect(protocolAdmin).mint(fan.address, price.mul(amountToBuy));

      // Approve Market to move currency
      await coin.connect(fan).approve(market.address, price.mul(amountToBuy));
    });

    it("Should distribute the right amount of sale value to the right stakeholders", async () => {
      // Get all fees.
      const totalPrice: BigNumber = price.mul(amountToBuy);

      const royaltyFeeBps: BigNumber = await accessNft.royaltyBps();
      const totalRoyalty: BigNumber = totalPrice.mul(royaltyFeeBps).div(MAX_BPS);

      const marketFeeBps: BigNumber = await market.marketFeeBps();
      const totalMarketFee: BigNumber = totalPrice.mul(marketFeeBps).div(MAX_BPS);

      const totalFeesCollected: BigNumber = totalRoyalty.add(totalMarketFee);
      console.log("Total fees collected: ", totalFeesCollected.toString());

      // Buy token
      await sendGaslessTx(fan, forwarder, relayer, {
        from: fan.address,
        to: market.address,
        data: market.interface.encodeFunctionData("buy", [listingId, amountToBuy]),
      });

      // Check Royalty contract balance
      expect(await coin.balanceOf(royaltyContract.address)).to.equal(totalFeesCollected);

      // Pull shares
      await royaltyContract.connect(stakeHolder1)["release(address,address)"](coin.address, stakeHolder1.address);
      await royaltyContract.connect(stakeHolder2)["release(address,address)"](coin.address, stakeHolder2.address);
      await royaltyContract.connect(stakeHolder3)["release(address,address)"](coin.address, stakeHolder3.address);
      await royaltyContract
        .connect(protocolProvider)
        ["release(address,address)"](coin.address, protocolProvider.address);

      // Get shares
      const totalShares = await royaltyContract.totalShares();
      const stakeholder1Shares = await royaltyContract.shares(stakeHolder1.address);
      const stakeholder2Shares = await royaltyContract.shares(stakeHolder2.address);
      const stakeholder3Shares = await royaltyContract.shares(stakeHolder3.address);
      const protocolProviderShares = await royaltyContract.shares(protocolProvider.address);

      // Check balances

      expect(await coin.balanceOf(stakeHolder1.address)).to.equal(
        totalFeesCollected.mul(stakeholder1Shares).div(totalShares),
      );
      expect(await coin.balanceOf(stakeHolder2.address)).to.equal(
        totalFeesCollected.mul(stakeholder2Shares).div(totalShares),
      );
      expect(await coin.balanceOf(stakeHolder3.address)).to.equal(
        totalFeesCollected.mul(stakeholder3Shares).div(totalShares),
      );
      expect(await coin.balanceOf(protocolProvider.address)).to.equal(
        totalFeesCollected.mul(protocolProviderShares).div(totalShares),
      );
    });
  });
});
