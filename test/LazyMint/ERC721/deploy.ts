import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC721 } from "typechain/LazyMintERC721";

// Types
import { BigNumber, BytesLike } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Initial state of LazyMintERC721 on deployment", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let defaultSaleRecipient: SignerWithAddress;

  // Contracts
  let lazyMintERC721: LazyMintERC721;

  // Deployment params
  const name: string = "Name";
  const symbol: string = "LAZY";
  const contractURI: string = "ipfs://contractURI/";
  let trustedForwarderAddr: string;
  let protocolControlAddr: string;
  let nativeTokenWrapperAddr: string;
  const royaltyBps: BigNumber = BigNumber.from(0);
  const feeBps: BigNumber = BigNumber.from(0);

  before(async () => {
    [protocolProvider, protocolAdmin, defaultSaleRecipient] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const contracts: Contracts = await getContracts(protocolProvider, protocolAdmin);

    trustedForwarderAddr = contracts.forwarder.address;
    protocolControlAddr = contracts.protocolControl.address;
    nativeTokenWrapperAddr = contracts.weth.address;

    lazyMintERC721 = await ethers
      .getContractFactory("LazyMintERC721")
      .then(f =>
        f
          .connect(protocolAdmin)
          .deploy(
            name,
            symbol,
            contractURI,
            protocolControlAddr,
            trustedForwarderAddr,
            nativeTokenWrapperAddr,
            defaultSaleRecipient.address,
            royaltyBps,
            feeBps,
          ),
      );
  });

  it("Should grant all relevant roles to contract deployer", async () => {
    const DEFAULT_ADMIN_ROLE: BytesLike = await lazyMintERC721.DEFAULT_ADMIN_ROLE();
    const MINTER_ROLE: BytesLike = await lazyMintERC721.MINTER_ROLE();
    const TRANSFER_ROLE: BytesLike = await lazyMintERC721.TRANSFER_ROLE();

    expect(await lazyMintERC721.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin.address)).to.be.true;
    expect(await lazyMintERC721.hasRole(MINTER_ROLE, protocolAdmin.address)).to.be.true;
    expect(await lazyMintERC721.hasRole(TRANSFER_ROLE, protocolAdmin.address)).to.be.true;
  });

  it("Should initialize relevant state variables in the constructor", async () => {
    expect(await lazyMintERC721.nativeTokenWrapper()).to.equal(nativeTokenWrapperAddr);
    expect(await lazyMintERC721.defaultSaleRecipient()).to.equal(defaultSaleRecipient.address);
    expect(await lazyMintERC721.contractURI()).to.equal(contractURI);
  });
});
