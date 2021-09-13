import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "@ethersproject/contracts";

import addresses from "../../utils/address.json";
import { getTxOptions } from "../../utils/txOptions";
import { BigNumber } from "ethers";

// Transaction parameters.
const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
const rewardURIs: string[] = [
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
];
const rewardSupplies: number[] = [5, 25, 60];
const openStartAndEnd: number = 0;
const rewardsPerOpen: number = 6;

async function main() {
  // Get signer + Rewards.sol contract + txOptions
  const [caller]: SignerWithAddress[] = await ethers.getSigners();
  const chainId: number = await caller.getChainId();
  console.log(`Performing tx with account: ${await caller.getAddress()} in chain: ${chainId}`);

  const networkName: string = hre.network.name;
  const rewards: Contract = await ethers.getContractAt(
    "Rewards",
    addresses[networkName as keyof typeof addresses].rewards,
  );
  const pack: Contract = await ethers.getContractAt("Pack", addresses[networkName as keyof typeof addresses].pack);

  const txOption = await getTxOptions(chainId);

  // Perform transaction.
  const packId: BigNumber = await pack.nextTokenId();

  const tx = await rewards.createPackAtomic(
    rewardURIs,
    rewardSupplies,
    packURI,
    openStartAndEnd,
    openStartAndEnd,
    rewardsPerOpen,
    txOption,
  );

  console.log("Creating packs: ", tx.hash);

  await tx.wait();

  // Display creator's pack balance
  const packBalance = await pack.balanceOf(await caller.getAddress(), packId);
  console.log("Pack balance: ", parseInt(packBalance.toString()), "Pack ID: ", packId);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
