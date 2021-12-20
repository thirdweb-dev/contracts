import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { LazyMintERC1155 } from "typechain/LazyMintERC1155";

// Types
import { BigNumber, BytesLike } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../../utils/tests/getContracts";

use(solidity);

describe("Initial state of LazyMintERC1155 on deployment", function () {
  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin: SignerWithAddress;
  let defaultSaleRecipient: SignerWithAddress;

  // Contracts
  let lazyMintERC1155: LazyMintERC1155;

  // Deployment params
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

    lazyMintERC1155 = await ethers
      .getContractFactory("LazyMintERC1155")
      .then(f =>
        f
          .connect(protocolAdmin)
          .deploy(
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
    const DEFAULT_ADMIN_ROLE: BytesLike = await lazyMintERC1155.DEFAULT_ADMIN_ROLE();
    const MINTER_ROLE: BytesLike = await lazyMintERC1155.MINTER_ROLE();
    const TRANSFER_ROLE: BytesLike = await lazyMintERC1155.TRANSFER_ROLE();

    expect(await lazyMintERC1155.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin.address)).to.be.true;
    expect(await lazyMintERC1155.hasRole(MINTER_ROLE, protocolAdmin.address)).to.be.true;
    expect(await lazyMintERC1155.hasRole(TRANSFER_ROLE, protocolAdmin.address)).to.be.true;
  });

  it("Should initialize relevant state variables in the constructor", async () => {
    expect(await lazyMintERC1155.nativeTokenWrapper()).to.equal(nativeTokenWrapperAddr);
    expect(await lazyMintERC1155.defaultSaleRecipient()).to.equal(defaultSaleRecipient.address);
    expect(await lazyMintERC1155.contractURI()).to.equal(contractURI);
  });
});
