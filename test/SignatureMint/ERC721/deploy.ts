import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Contract Types
import { SignatureMint721 } from "typechain/SignatureMint721";

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
  let sigMint721: SignatureMint721;

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

    sigMint721 = (await ethers
      .getContractFactory("SignatureMint721")
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
      )) as SignatureMint721;
  });

  it("Should grant all relevant roles to contract deployer", async () => {
    const DEFAULT_ADMIN_ROLE: BytesLike = await sigMint721.DEFAULT_ADMIN_ROLE();
    const MINTER_ROLE: BytesLike = await sigMint721.MINTER_ROLE();
    const TRANSFER_ROLE: BytesLike = await sigMint721.TRANSFER_ROLE();

    expect(await sigMint721.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin.address)).to.be.true;
    expect(await sigMint721.hasRole(MINTER_ROLE, protocolAdmin.address)).to.be.true;
    expect(await sigMint721.hasRole(TRANSFER_ROLE, protocolAdmin.address)).to.be.true;
  });

  it("Should initialize relevant state variables in the constructor", async () => {
    expect(await sigMint721.nativeTokenWrapper()).to.equal(nativeTokenWrapperAddr);
    expect(await sigMint721.defaultSaleRecipient()).to.equal(defaultSaleRecipient.address);
    expect(await sigMint721.contractURI()).to.equal(contractURI);
  });
});
