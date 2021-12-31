import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Types
import { ProtocolControl, Registry, Royalty } from "typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Helpers
import { getContracts } from "../../utils/tests/getContracts";

use(solidity);

describe("Deploy proxies for Royalty module", function() {

  // Signers
  let protocolProvider: SignerWithAddress;
  let protocolAdmin_dummy: SignerWithAddress;
  let protocolAdmin_1: SignerWithAddress;
  let protocolAdmin_2: SignerWithAddress;

  // Contracts
  let controlCenter: ProtocolControl;
  let royaltyContract: Royalty;
  let proxyForRoyalty: Royalty;

  // Initialization params
  let trustedForwarderAddr: string;
  let uri: string;
  let payees: string[];
  let shares: number[];

  function scaleShares(_shares: number[]): number[] {
    return _shares.map(val => val * 10_000);
  }

  before(async () => {
    // Get signers
    [protocolProvider, protocolAdmin_dummy, protocolAdmin_1, protocolAdmin_2] = await ethers.getSigners();

    // Get initialize params
    const contracts = await getContracts(protocolProvider, protocolAdmin_dummy);
    controlCenter = contracts.protocolControl;
    trustedForwarderAddr = contracts.forwarder.address;
    uri = "ipfs://"
    payees = [protocolAdmin_dummy.address, protocolAdmin_1.address, protocolAdmin_2.address]
    shares = [20, 40, 40];

    // Deploy Royalty implementation
    royaltyContract = await ethers.getContractFactory("Royalty").then(f => f.deploy());
  })

  beforeEach(async () => {
    const thirdwebProxy = await ethers.getContractFactory("ThirdwebProxy")
      .then(f => f.deploy(
        royaltyContract.address,
        royaltyContract.interface.encodeFunctionData("initialize", [controlCenter.address, trustedForwarderAddr, uri, payees, shares])
      )
    );

    proxyForRoyalty = await ethers.getContractAt("Royalty", thirdwebProxy.address) as Royalty;
  })

  it("Should initialize the proxied royalty contract", async () => {
    expect(await proxyForRoyalty.contractURI()).to.equal(uri);
    expect(await proxyForRoyalty.totalShares()).to.equal(scaleShares(shares).reduce((a,b) => a+b));

    for(let i = 0; i < payees.length; i += 1) {
      expect(await proxyForRoyalty.shares(payees[i])).to.equal(scaleShares(shares)[i]);
    }
  })

  it("Should revert on trying to re-initialize contract via proxy", async () => {
    await expect(
      proxyForRoyalty.initialize(controlCenter.address, trustedForwarderAddr, uri, payees, shares)
    ).to.be.revertedWith("Initializable: contract is already initialized");
  })
})