// Test imports
import { ethers, network } from "hardhat";
import { expect } from "chai";

// Types
import { AccessNFTPL } from "../../typechain/AccessNFTPL";
import { PackPL } from "../../typechain/PackPL";
import { Forwarder } from "../../typechain/Forwarder";
import { BytesLike } from "@ethersproject/bytes";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Test utils
import { getContracts, Contracts } from "../../utils/tests/getContracts";
import { getURIs, getAmounts } from "../../utils/tests/params";
import { forkFrom, impersonate } from "../../utils/hardhatFork";
import { sendGaslessTx } from "../../utils/tests/gasless";
import linkTokenABi from "../../abi/LinkTokenInterface.json";
import { chainlinkVars } from "../../utils/chainlink";

describe("VRF fulfills a randomness request", function () {
  // Signers
  let protocolAdmin: SignerWithAddress;
  let creator: SignerWithAddress;
  let relayer: SignerWithAddress;
  let vrf: SignerWithAddress;

  // Contracts
  let pack: PackPL;
  let accessNft: AccessNFTPL;
  let forwarder: Forwarder;

  // Reward parameters
  const [packURI]: string[] = getURIs(1);
  const rewardURIs: string[] = getURIs();
  const accessURIs = getURIs(rewardURIs.length);
  const rewardSupplies: number[] = getAmounts(rewardURIs.length);
  const openStartAndEnd: number = 0;
  const rewardsPerOpen: number = 1;

  // Token IDs
  let packId: number;
  let rewardIds: number[];

  // Randomness request ID
  let requestId: BytesLike;
  const randomNumber: number = Math.floor(10000 * (1 + Math.random()));

  // Network
  const networkName = "rinkeby";

  const createPack = async (
    _packCreator: SignerWithAddress,
    _rewardURIs: string[],
    _accessURIs: string[],
    _rewardAmounts: number[],
    _packAddress: string,
    _encodedParamsAsData: BytesLike,
  ) => {
    await sendGaslessTx(_packCreator, forwarder, relayer, {
      from: _packCreator.address,
      to: accessNft.address,
      data: accessNft.interface.encodeFunctionData("createAccessNfts", [
        _rewardURIs,
        _accessURIs,
        _rewardAmounts,
        _packAddress,
        _encodedParamsAsData,
      ])
    });
  };

  const encodeParams = (
    packURI: string,
    secondsUntilOpenStart: number,
    secondsUntilOpenEnd: number,
    rewardsPerOpen: number,
  ) => {
    return ethers.utils.defaultAbiCoder.encode(
      ["string", "uint256", "uint256", "uint256"],
      [packURI, secondsUntilOpenStart, secondsUntilOpenEnd, rewardsPerOpen],
    );
  };

  // Fund `Pack` with LINK
  const fundPack = async () => {
    const { linkTokenAddress } = chainlinkVars[networkName];

    const linkHolderAddress: string = "0xa7a82dd06901f29ab14af63faf3358ad101724a8";
    await impersonate(linkHolderAddress);
    const linkHolder: SignerWithAddress = await ethers.getSigner(linkHolderAddress);

    const linkContract = await ethers.getContractAt(linkTokenABi, linkTokenAddress);
    linkContract.connect(linkHolder).transfer(pack.address, ethers.utils.parseEther("1"));
  };

  // Impersonate Chainlink VRF: setup
  const impersonateChainlinkVRF = async (): Promise<SignerWithAddress> => {
    const { vrfCoordinator } = chainlinkVars[networkName];

    // Impersonate VRF
    await impersonate(vrfCoordinator);
    const vrf: SignerWithAddress = await ethers.getSigner(vrfCoordinator);

    await network.provider.send("hardhat_setBalance", [vrfCoordinator, "0xDE0B6B3A7640000"]);

    return vrf;
  };

  before(async () => {
    // Fork rinkeby for testing
    await forkFrom(networkName);

    // Get signers
    const signers: SignerWithAddress[] = await ethers.getSigners();
    [protocolAdmin, creator, relayer] = signers;

    // Impersonate vrf
    vrf = await impersonateChainlinkVRF();
  });

  beforeEach(async () => {
    // Get contracts
    const contracts: Contracts = await getContracts(protocolAdmin, networkName);
    pack = contracts.pack;
    accessNft = contracts.accessNft;
    forwarder = contracts.forwarder;

    // Get pack ID
    packId = parseInt((await pack.nextTokenId()).toString());

    // Create packs
    await createPack(
      creator,
      rewardURIs,
      accessURIs,
      rewardSupplies,
      pack.address,
      encodeParams(packURI, openStartAndEnd, openStartAndEnd, rewardsPerOpen),
    );

    // Get rewardIds
    const nextAccessNftId: number = parseInt((await accessNft.nextTokenId()).toString());
    const expectedRewardIds: number[] = [];
    for (let val of [...Array(nextAccessNftId).keys()]) {
      if (val % 2 != 0) {
        expectedRewardIds.push(val);
      }
    }

    rewardIds = expectedRewardIds;

    // Fund pack contract with LINK
    await fundPack();

    // Open pack
    await sendGaslessTx(creator, forwarder, relayer, {
      from: creator.address,
      to: pack.address,
      data: pack.interface.encodeFunctionData("openPack", [packId]),
    });

    requestId = await pack.currentRequestId(packId, creator.address);
  });

  describe("Revert cases", function () {
    it("Should revert if caller is not VRF coordinator", async () => {
      await expect(pack.connect(protocolAdmin).rawFulfillRandomness(requestId, randomNumber)).to.be.reverted;
    });
  });

  describe("Events", function () {
    it("Should emit PackOpenFulfilled", async () => {
      const eventPromise = new Promise((resolve, reject) => {
        pack.on("PackOpenFulfilled", (_packId, _receiver, _requestId, _rewardSource, _rewardIds) => {
          expect(_packId).to.equal(packId);
          expect(_receiver).to.equal(creator.address);
          expect(_requestId).to.equal(requestId);
          expect(_rewardSource).to.equal(accessNft.address);
          expect(_rewardIds.length).to.equal(rewardsPerOpen);

          const id = parseInt(_rewardIds[0].toString());
          expect(rewardIds.includes(id)).to.equal(true);

          resolve(null);
        });

        setTimeout(() => {
          reject(new Error("Timeout PackOpenFulfilled"));
        }, 10000);
      });

      await pack.connect(vrf).rawFulfillRandomness(requestId, randomNumber);

      try {
        await eventPromise;
      } catch (e) {
        console.error(e);
      }
    });
  });

  describe("Balances", function () {
    beforeEach(async () => {
      await pack.connect(vrf).rawFulfillRandomness(requestId, randomNumber);
    });

    it("Should increment the opener's balance of one of the underlying rewards by 1", async () => {
      let balanceUpdated: boolean = false;
      for (let id of rewardIds) {
        const bal: number = parseInt((await accessNft.balanceOf(creator.address, id)).toString());
        if (bal == 1) {
          if (!balanceUpdated) {
            balanceUpdated = true;
          } else {
            throw new Error("Too many rewards distributed");
          }
        }
      }

      expect(balanceUpdated).to.equal(true);
    });
  });

  describe("Contract state", async () => {
    let distributedRewardId: number;

    beforeEach(async () => {
      await pack.connect(vrf).rawFulfillRandomness(requestId, randomNumber);

      for (let id of rewardIds) {
        const bal: number = parseInt((await accessNft.balanceOf(creator.address, id)).toString());
        if (bal == 1) {
          distributedRewardId = id;
        }
      }
    });

    it("Should update the amount of rewards packed in the rewards mapping", async () => {
      const rewardsInPack = await pack.getPackWithRewards(packId);

      const rewardIdsOfPacked: BigNumber[] = rewardsInPack.tokenIds;
      const amountsPacked: BigNumber[] = rewardsInPack.amountsPacked;

      expect(rewardIdsOfPacked.length).to.equal(amountsPacked.length);

      for (let i = 0; i < rewardIdsOfPacked.length; i++) {
        if (parseInt(rewardIdsOfPacked[i].toString()) == distributedRewardId) {
          expect(amountsPacked[i]).to.equal(rewardSupplies[i] - 1);
        } else {
          continue;
        }
      }
    });

    it("Should delete the 'currentRequestId' for the opener and pack", async () => {
      const currentRequestId: BytesLike = await pack.currentRequestId(packId, creator.address);
      expect(currentRequestId).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
    });
  });
});
