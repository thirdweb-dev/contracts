import { ethers } from "hardhat";
import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";

// Types
import { ProtocolControl, Registry, Royalty } from "typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Helpers
import { getContracts } from "../../utils/tests/getContracts";

use(solidity);

describe("Test royalty functionality", function() {

  // Signers
  let protocolProvider: SignerWithAddress;
  let royalty_admin: SignerWithAddress;
  let shareHolder_1: SignerWithAddress;
  let shareHolder_2: SignerWithAddress;
  let registryFeeRecipient: SignerWithAddress;

  // Contracts
  let royaltyContract: Royalty;
  let proxyForRoyalty: Royalty;

  // Initialization params
  let controlCenterAddr: string;
  let trustedForwarderAddr: string;
  let uri: string;
  let payees: string[];
  let shares: number[];

  function scaleShares(_shares: number[]): number[] {
    return _shares.map(val => val * 10_000);
  }

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
    controlCenterAddr = contracts.protocolControl.address;
    trustedForwarderAddr = contracts.forwarder.address;
    uri = "ipfs://"
    payees = [royalty_admin.address, shareHolder_1.address, shareHolder_2.address]
    shares = [20, 40, 40];

    // Deploy Royalty implementation
    royaltyContract = await ethers.getContractFactory("Royalty").then(f => f.deploy());
  })

  beforeEach(async () => {
    const thirdwebProxy = await ethers.getContractFactory("ThirdwebProxy")
      .then(f => f.connect(royalty_admin).deploy(
        royaltyContract.address,
        royaltyContract.interface.encodeFunctionData(
          "initialize",
          [controlCenterAddr, trustedForwarderAddr, uri, payees, shares]
        )
      )
    );

    proxyForRoyalty = await ethers.getContractAt("Royalty", thirdwebProxy.address) as Royalty;
  })
})