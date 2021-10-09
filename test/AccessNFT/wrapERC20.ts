// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { Coin } from "../../typechain/Coin";
import { NFTWrapper } from "../../typechain/NFTWrapper";
import { Forwarder } from "../../typechain/Forwarder";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContractsPermissioned";
import { getAmounts, getURIs } from "../../utils/tests/params";
import { forkFrom } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";
import { BigNumber } from "ethers";


describe("Wrapping ERC20 tokens as Access NFT", function () {
  // Signers
  let deployer: SignerWithAddress;
  let fan: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let accessNft: AccessNFT;
  let forwarder: Forwarder;
  let coin: Coin;
  let nftWrapper: NFTWrapper;

  // ERC20 parameters
  const nftURIs: string[] = getURIs(3);
  const tokenAmounts: BigNumber[] = [
    ethers.utils.parseEther("100"),
    ethers.utils.parseEther("100"),
    ethers.utils.parseEther("100")
  ];
  const totalAmount: BigNumber = tokenAmounts.reduce((a,b) => a.add(b));
  const numOfSharesOfEach: number[] = [10, 50, 500]

  // Redeem Parameters
  const wrappedTokenIds: number[] = [0,1,2];
  const amountToRedeeem: number = 1;

  // Network
  const networkName = "rinkeby";

  before(async () => {
    // Fork rinkeby for testing
    await forkFrom(networkName);

    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [deployer, fan, relayer] = signers;
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(deployer, networkName);
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;
    coin = contracts.coin;
    nftWrapper = contracts.nftWrapper;

    // Grant Minter role to fan
    const MINTER_ROLE = await accessNft.MINTER_ROLE();
    await accessNft.connect(deployer).grantRole(MINTER_ROLE, fan.address);

    // Mint NFT to fan
    await coin.mint(fan.address, totalAmount);

    // Approve NFT wrapper to transfer NFTs
    await coin.connect(fan).approve(nftWrapper.address, totalAmount);
  });

  it("Should wrap ERC20 tokens and mint the wrapped tokens to the ERC20 token owner", async () => {

    expect(await coin.balanceOf(fan.address)).to.equal(totalAmount);
    expect(await coin.balanceOf(nftWrapper.address)).to.equal(0);

    for(let i = 0 ; i < wrappedTokenIds.length; i += 1) {
      expect(await accessNft.balanceOf(fan.address, wrappedTokenIds[i])).to.equal(0);
    }

    // Wrap ERC20 tokens
    await sendGaslessTx(
      fan,
      forwarder,
      relayer,
      {
        from: fan.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("wrapERC20", [
          [coin.address, coin.address, coin.address],
          tokenAmounts,
          numOfSharesOfEach,
          nftURIs
        ])
      }
    )

    expect(await coin.balanceOf(fan.address)).to.equal(0);
    expect(await coin.balanceOf(nftWrapper.address)).to.equal(totalAmount);
    
    for(let i = 0 ; i < wrappedTokenIds.length; i += 1) {
      expect(await accessNft.balanceOf(fan.address, wrappedTokenIds[i])).to.equal(numOfSharesOfEach[i]);
    }
  })

  it("Should let redeemable wrapped ERC20 token owner redeem the ERC20 tokens", async () => {

    // Wrap ERC20 tokens
    await sendGaslessTx(
      fan,
      forwarder,
      relayer,
      {
        from: fan.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("wrapERC20", [
          [coin.address, coin.address, coin.address],
          tokenAmounts,
          numOfSharesOfEach,
          nftURIs
        ])
      }
    )

    const targetWrappedTokenId: number = wrappedTokenIds[0];
    const totalSharesOfWrapped: number = numOfSharesOfEach[0];

    expect(await coin.balanceOf(fan.address)).to.equal(0);
    expect(await coin.balanceOf(nftWrapper.address)).to.equal(totalAmount);
    expect(await accessNft.balanceOf(fan.address, targetWrappedTokenId)).to.equal(totalSharesOfWrapped);

    // Redeem 1 share of wrapped ERC20 token
    await sendGaslessTx(
      fan,
      forwarder,
      relayer,
      {
        from: fan.address,
        to: accessNft.address,
        data: accessNft.interface.encodeFunctionData("redeemToken", [targetWrappedTokenId, amountToRedeeem])
      }
    );

    const shareCollected = tokenAmounts[0].div(totalSharesOfWrapped);
    
    expect(await coin.balanceOf(fan.address)).to.equal(shareCollected);
    expect(await coin.balanceOf(nftWrapper.address)).to.equal(totalAmount.sub(shareCollected));
    expect(await accessNft.balanceOf(fan.address, targetWrappedTokenId)).to.equal(totalSharesOfWrapped - amountToRedeeem);
  })
});
