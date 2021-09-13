import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";

import { getChainlinkVars, ChainlinkVars } from "../utils/chainlink";
import { getContractAddress } from "../utils/contracts";

import LinkTokenABI from "../abi/LinkTokenInterface.json";

/// NOTE: set the right netowrk.

async function main() {
  const [funder] = await ethers.getSigners();
  const chainId: number = await funder.getChainId();

  console.log(`Funding with LINK on chain: ${chainId} by account: ${await funder.getAddress()}`);

  // Get LINK contract
  const { linkTokenAddress } = (await getChainlinkVars(chainId)) as ChainlinkVars;
  const packAddress = await getContractAddress("pack", chainId);
  const linkContract: Contract = await ethers.getContractAt(LinkTokenABI, linkTokenAddress as string);

  // Fund pack contract.
  const amountToFund: BigNumber = ethers.utils.parseEther("1");
  const transferTx = await linkContract.connect(funder).transfer(packAddress, amountToFund);
  console.log("Transferring link: ", transferTx.hash);

  await transferTx.wait();
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
