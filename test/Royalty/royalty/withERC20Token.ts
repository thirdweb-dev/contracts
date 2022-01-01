import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Types
import { ProtocolControl, Registry, Royalty, Coin } from "typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Helpers
import { getContracts } from "../../../utils/tests/getContracts";
import { BigNumber } from "ethers";

use(solidity);

describe("Test royalty functionality", function() {

  const FACTOR: number = 10_000;

  // Signers
  let protocolProvider: SignerWithAddress;
  let royalty_admin: SignerWithAddress;
  let shareHolder_1: SignerWithAddress;
  let shareHolder_2: SignerWithAddress;
  let registryFeeRecipient: SignerWithAddress;

  // Contracts
  let registry: Registry;
  let controlCenter: ProtocolControl;
  let royaltyContract: Royalty;
  let proxyForRoyalty: Royalty;
  let erc20Token: Coin;

  // Initialization params
  let trustedForwarderAddr: string;
  let uri: string;
  let payees: SignerWithAddress[];
  let shares: number[];

  function scaleShares(_shares: number[]): number[] {
    return _shares.map(val => val * 10_000);
  }

  const mintERC20To = async (to: string, amount: BigNumber) => {
    // Mint currency to buyer
    await erc20Token.connect(royalty_admin).mint(to, amount);
  };

  before(async () => {
    // Get signers
    [
      protocolProvider,
      royalty_admin,
      shareHolder_1,
      shareHolder_2,
      registryFeeRecipient,
    ] = await ethers.getSigners();

    // Get initialize params
    const contracts = await getContracts(protocolProvider, royalty_admin);
    erc20Token = contracts.coin;
    registry = contracts.registry;
    controlCenter = contracts.protocolControl;
    trustedForwarderAddr = contracts.forwarder.address;
    uri = "ipfs://"
    payees = [royalty_admin, shareHolder_1, shareHolder_2]
    shares = [2000, 4000, 4000];

    // Deploy Royalty implementation
    royaltyContract = await ethers.getContractFactory("Royalty").then(f => f.deploy());
  })
  describe("Test: Royalty contract functionality", function() {

    beforeEach(async () => {
      const thirdwebProxy = await ethers.getContractFactory("ThirdwebProxy")
        .then(f => f.connect(royalty_admin).deploy(
          royaltyContract.address,
          royaltyContract.interface.encodeFunctionData(
            "initialize",
            [
              controlCenter.address,
              trustedForwarderAddr,
              uri,
              payees.map(signer => signer.address),
              shares
            ]
          )
        )
      );
  
      proxyForRoyalty = await ethers.getContractAt("Royalty", thirdwebProxy.address) as Royalty;
  
      // Send 100_000 tokens to contract
      await mintERC20To(proxyForRoyalty.address, ethers.utils.parseEther("100000"));
    })

    
    it("Should be initialized with the right shares for respective shareholders", async () => {
      for(let i = 0; i < payees.length; i += 1) {
        expect(await proxyForRoyalty.shares(payees[i].address)).to.equal(scaleShares(shares)[i]);
      }
    })

    it("Should release the appropriate share of the contract balance to shareholders", async () => {
      const totalMoneyInContract: BigNumber = await erc20Token.balanceOf(proxyForRoyalty.address);
      const totalSharesScaled = shares.reduce((a,b) => a+b) * FACTOR;

      for(let i = 0; i < payees.length; i += 1) {
        const shareholderShares = await proxyForRoyalty.shares(payees[i].address)

        const shareholderPayout = (totalMoneyInContract.mul(shareholderShares)).div(totalSharesScaled)

        const shareholderBalBefore: BigNumber = await erc20Token.balanceOf(payees[i].address);
        await proxyForRoyalty.connect(protocolProvider)["release(address,address)"](erc20Token.address, payees[i].address);
        const shareholderBalAfter: BigNumber = await erc20Token.balanceOf(payees[i].address);

        expect(shareholderBalAfter).to.equal(shareholderBalBefore.add(shareholderPayout));
      }
    });

    it("Should revert if the a non-shareholder tries to release money from the contract", async () => {
      const non_shareholder = protocolProvider;

      await expect(
        proxyForRoyalty.connect(non_shareholder)["release(address,address)"](erc20Token.address, non_shareholder.address)
      ).to.be.revertedWith("aymentSplitter: account has no shares")
    });

    it("Should revert if a shareholder is not due any payement", async () => {
      const payee = payees[0];
      
      await proxyForRoyalty.connect(payee)["release(address,address)"](erc20Token.address, payee.address);
      await expect(
        proxyForRoyalty.connect(payee)["release(address,address)"](erc20Token.address, payee.address)
      ).to.be.revertedWith("PaymentSplitter: account is not due payment")
    });

    it("Should emit PaymentReleased with the release info for each shareholder", async () => {
      const totalMoneyInContract: BigNumber = await erc20Token.balanceOf(proxyForRoyalty.address);
      const totalSharesScaled = shares.reduce((a,b) => a+b) * FACTOR;

      for(let i = 0; i < payees.length; i += 1) {
        const shareholderShares = await proxyForRoyalty.shares(payees[i].address)
        const shareholderPayout = (totalMoneyInContract.mul(shareholderShares)).div(totalSharesScaled)

        await expect(
          proxyForRoyalty.connect(protocolProvider)["release(address,address)"](erc20Token.address, payees[i].address)
        ).to.emit(proxyForRoyalty, "ERC20PaymentReleased")
        .withArgs(
          ...Object.values({
            token: erc20Token.address,
            account: payees[i].address,
            payment: shareholderPayout
          })
        );
      }
    })
  })

  describe("Test: Add registry treasury as shareholder, and set royalty contract as royalty treasury on ProtocolControl", function() {

    let payeesWithFeeRecipient: SignerWithAddress[] = [];
    let sharesAdjustedForFee: BigNumber[] = [];
    let feeBps: BigNumber;

    beforeEach(async () => {

      // Get fee bps:
      feeBps = await registry.getFeeBps(controlCenter.address);

      // Set new registry treasury and update payess
      await registry.connect(protocolProvider).setTreasury(registryFeeRecipient.address);
      payeesWithFeeRecipient = payees.concat([registryFeeRecipient]);

      // Adjust shares for fee.
      sharesAdjustedForFee = []
      let feeShares: BigNumber = BigNumber.from(0);
      for(let i = 0; i < shares.length; i += 1) {
        const feeCut = (feeBps.mul(shares[i])).div(FACTOR);
        sharesAdjustedForFee.push(BigNumber.from(shares[i]).sub(feeCut));
        feeShares = feeShares.add(feeCut);
      }
      sharesAdjustedForFee.push(feeShares);

      const thirdwebProxy = await ethers.getContractFactory("ThirdwebProxy")
        .then(f => f.connect(royalty_admin).deploy(
          royaltyContract.address,
          royaltyContract.interface.encodeFunctionData(
            "initialize",
            [
              controlCenter.address,
              trustedForwarderAddr,
              uri,
              payeesWithFeeRecipient.map(signer => signer.address),
              sharesAdjustedForFee
            ]
          )
        )
      );
  
      proxyForRoyalty = await ethers.getContractAt("Royalty", thirdwebProxy.address) as Royalty;
  
      // Send 100 ether to contract
      await protocolProvider.sendTransaction({
        to: proxyForRoyalty.address,
        value: ethers.utils.parseEther("100")
      });
    })

    it("Should set the right shares for shareholders, taking fee into account", async () => {
      const scaledSharesAdjustedForFees = scaleShares(sharesAdjustedForFee.map(x => x.toNumber()))
      for(let i = 0; i < payeesWithFeeRecipient.length; i += 1) {
        expect(await proxyForRoyalty.shares(payeesWithFeeRecipient[i].address)).to.equal(scaledSharesAdjustedForFees[i]);
      }
    });

    it("Should successfully set royalty contract as royalty treasury on ProtocolControl", async () => {
      await expect(
        controlCenter.connect(royalty_admin).setRoyaltyTreasury(proxyForRoyalty.address)
      ).to.not.be.reverted;
    })
  })
})