// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFTPL } from "../../typechain/AccessNFTPL";
import { Forwarder } from "../../typechain/Forwarder";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts, getAmountBounded } from "../../utils/tests/params";
import { forkFrom } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";
import { BigNumber } from "ethers";

describe("Calling 'createAccessNfts'", function () {
  // Signers
  let deployer: SignerWithAddress;
  let creator: SignerWithAddress;
  let fan: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let accessNft: AccessNFTPL;
  let forwarder: Forwarder;

  // Reward parameters
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getAmounts(rewardURIs.length);

  // Redeem Parameters
  const amountToRedeeem: number = 1;
  let rewardId: number = 1;
  let accessId: number = 0;

  // Network
  const networkName = "rinkeby";

  before(async () => {

    // Fork rinkeby for testing
    await forkFrom(networkName);

    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [deployer, creator, fan, relayer] = signers;
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(deployer, networkName);
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;

    // Create access NFTs
    await sendGaslessTx(
      creator,
      forwarder,
      relayer,
      {
        from: creator.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("createAccessNfts", [
          rewardURIs,
          accessURIs,
          rewardSupplies
        ])
      }
    )
  })

  describe("Revert cases", function() {

    it("Should revert if token is not of redeemable type", async () => {
      // Creator redeems a token for a non-redeemable token.
      await sendGaslessTx(
        creator,
        forwarder,
        relayer,
        {
          from: creator.address,
          to: accessNft.address,
          data: accessNft.interface.encodeFunctionData("redeemAccess", [rewardId, amountToRedeeem])
        }
      );

      await expect(
        accessNft.connect(creator).redeemAccess(accessId, 1)
      ).to.be.revertedWith("AccessNFT: This token is not redeemable for access.")
    })

    it("Should revert if caller owns no redeemable token", async () => {
      await expect(
        accessNft.connect(fan).redeemAccess(rewardId, 1)
      ).to.be.revertedWith("AccessNFT: Cannot redeem more NFTs than owned.")
    })

    it("Should revert if the window to redeem access tokens has ended", async () => {

      // Creator sets limit for access token redemption
      const secondsUntilWindowEnd: number = 100;
      await sendGaslessTx(
        creator,
        forwarder,
        relayer,
        {
          from: creator.address,
          to: accessNft.address,
          data: accessNft.interface.encodeFunctionData("setLastTimeToRedeem", [accessId, secondsUntilWindowEnd])
        }
      )

      // Time travel
      for(let i = 0; i < secondsUntilWindowEnd; i++) {
        await ethers.provider.send("evm_mine", []);
      }

      await expect(
        accessNft.connect(creator).redeemAccess(rewardId, 1)
      ).to.be.revertedWith("AccessNFT: Window to redeem access has closed.")
    })
  })

  describe("Events", function() {

    it("Should emit AccessNFTRedeemed", async () => {
      const eventPromise = new Promise((resolve, reject) => {
        accessNft.on("AccessNFTRedeemed", (_redeemer: string, _rewardId: number, _accessId: number, _amount: number) => {
          expect(_redeemer).to.equal(fan.address);
          expect(_rewardId).to.equal(rewardId);
          expect(_accessId).to.equal(accessId);
          expect(_amount).to.equal(amountToRedeeem);

          resolve(null)
        })

        setTimeout(() => {
          reject(new Error("Timeout AccessNFTRedeemed"))
        }, 5000);
      })
  
      // Send reward to fan
      await sendGaslessTx(
        creator,
        forwarder,
        relayer,
        {
          from: creator.address,
          to: accessNft.address,
          data: accessNft.interface.encodeFunctionData("safeTransferFrom", [
            creator.address, fan.address, rewardId, amountToRedeeem, ethers.utils.toUtf8Bytes("")
          ])
        }
      )

      // Redeem access NFT
      await sendGaslessTx(
        fan,
        forwarder,
        relayer,
        {
          from: fan.address,
          to: accessNft.address,
          data: accessNft.interface.encodeFunctionData("redeemAccess", [rewardId, amountToRedeeem])
        }
      )
      
      try {
        await eventPromise;
      } catch(e) {
        console.error(e);
      }
    })
  })

  describe("Balances", function() {

    beforeEach(async () => {
      // Send reward to fan
      await sendGaslessTx(
        creator,
        forwarder,
        relayer,
        {
          from: creator.address,
          to: accessNft.address,
          data: accessNft.interface.encodeFunctionData("safeTransferFrom", [
            creator.address, fan.address, rewardId, amountToRedeeem, ethers.utils.toUtf8Bytes("")
          ])
        }
      )
    })

    it("Should burn away all un-redeemed rewards of the redeemer", async () => {
      
      expect(await accessNft.balanceOf(fan.address, rewardId)).to.equal(amountToRedeeem);
      
      // Redeem access NFT
      await sendGaslessTx(
        fan,
        forwarder,
        relayer,
        {
          from: fan.address,
          to: accessNft.address,
          data: accessNft.interface.encodeFunctionData("redeemAccess", [rewardId, amountToRedeeem])
        }
      )

      expect(await accessNft.balanceOf(fan.address, rewardId)).to.equal(0);
    })

    it("Should mint all redeemed access rewards to fan", async () => {
      expect(await accessNft.balanceOf(fan.address, accessId)).to.equal(0);
      
      const contractBalanceOfAccessBefore: BigNumber = await accessNft.balanceOf(accessNft.address, accessId)
      
      // Redeem access NFT
      await sendGaslessTx(
        fan,
        forwarder,
        relayer,
        {
          from: fan.address,
          to: accessNft.address,
          data: accessNft.interface.encodeFunctionData("redeemAccess", [rewardId, amountToRedeeem])
        }
      )

      const contractBalanceOfAccessAfter: BigNumber = await accessNft.balanceOf(accessNft.address, accessId)

      expect(await accessNft.balanceOf(fan.address, accessId)).to.equal(amountToRedeeem);
      expect(contractBalanceOfAccessBefore.sub(contractBalanceOfAccessAfter)).to.equal(1);
    })
  })
});
