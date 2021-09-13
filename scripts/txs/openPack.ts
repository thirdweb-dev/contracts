import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "@ethersproject/contracts";

import addresses from "../../utils/address.json";
import { getTxOptions } from "../../utils/txOptions";

// Transaction parameters.
const packId: number = 0;

async function main() {
  // Get signer + Rewards.sol contract + txOptions
  const [caller]: SignerWithAddress[] = await ethers.getSigners();
  const chainId: number = await caller.getChainId();
  console.log(`Performing tx with account: ${await caller.getAddress()} in chain: ${chainId}`);

  const networkName: string = hre.network.name;
  const pack: Contract = await ethers.getContractAt("Pack", addresses[networkName as keyof typeof addresses].pack);

  const txOption = await getTxOptions(chainId);

  // Display creator's pack balance
  const packBalance = await pack.balanceOf(await caller.getAddress(), packId);
  console.log("Pack balance: ", parseInt(packBalance.toString()), "Pack ID: ", packId);

  // Perform transaction.
  const tx = await pack.openPack(packId, txOption);
  console.log("Opening pack: ", tx.hash);

  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
