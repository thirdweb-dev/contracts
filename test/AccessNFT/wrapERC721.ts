// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFT } from "../../typechain/AccessNFT";
import { NFT } from "../../typechain/NFT";
import { NFTWrapper } from "../../typechain/NFTWrapper";
import { Forwarder } from "../../typechain/Forwarder";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs } from "../../utils/tests/params";
import { forkFrom } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";

describe("Wrapping an ERC 721 NFT as Access NFT", function () {
  // Signers
  let deployer: SignerWithAddress;
  let fan: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Contracts
  let accessNft: AccessNFT;
  let forwarder: Forwarder;
  let nft: NFT;
  let nftWrapper: NFTWrapper;

  // NFT parameters
  const nftTokenId: number = 0;
  const wrappedTokenId: number = 0;
  const [nftURI]: string[] = getURIs(1);

  // Redeem Parameters
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
    nft = contracts.nft;
    nftWrapper = contracts.nftWrapper;

    // Grant Minter role to fan
    const MINTER_ROLE = await accessNft.MINTER_ROLE();
    await accessNft.connect(deployer).grantRole(MINTER_ROLE, fan.address);

    // Mint NFT to fan
    await nft.mintNFT(fan.address, nftURI);

    // Approve NFT wrapper to transfer NFTs
    await nft.connect(fan).approve(nftWrapper.address, nftTokenId);
  });

  it("Should wrap ERC721 NFT and mint the wrapped token to the NFT owner", async () => {
    expect(await accessNft.balanceOf(fan.address, wrappedTokenId)).to.equal(0);
    expect(await nft.ownerOf(nftTokenId)).to.equal(fan.address);

    // Wrap NFT
    await sendGaslessTx(fan, forwarder, relayer, {
      from: fan.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("wrapERC721", [[nft.address], [nftTokenId], [nftURI]]),
    });

    expect(await accessNft.balanceOf(fan.address, wrappedTokenId)).to.equal(1);
    expect(await nft.ownerOf(nftTokenId)).to.equal(nftWrapper.address);
  });

  it("Should let redeemable erapped ERC721 token owner redeem the ERC 721 NFT", async () => {
    // Wrap NFT
    await sendGaslessTx(fan, forwarder, relayer, {
      from: fan.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("wrapERC721", [[nft.address], [nftTokenId], [nftURI]]),
    });

    expect(await accessNft.balanceOf(fan.address, wrappedTokenId)).to.equal(1);
    expect(await nft.ownerOf(nftTokenId)).to.equal(nftWrapper.address);

    // Redeem NFT
    await sendGaslessTx(fan, forwarder, relayer, {
      from: fan.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("redeemToken", [wrappedTokenId, amountToRedeeem]),
    });

    expect(await accessNft.balanceOf(fan.address, wrappedTokenId)).to.equal(0);
    expect(await nft.ownerOf(nftTokenId)).to.equal(fan.address);
  });
});
