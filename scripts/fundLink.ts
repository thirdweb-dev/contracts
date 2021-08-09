import { ethers } from "hardhat";
import { BigNumber, Contract } from 'ethers';

import { chainlinkVars } from "../utils/chainlink";
import { addresses } from "../utils/contracts";

import LinkTokenABI from "../abi/LinkTokenInterface.json";

/// NOTE: set the right netowrk.

async function main() {
  const [funder] = await ethers.getSigners();

  // Get LINK contract
  const { linkTokenAddress } = chainlinkVars.rinkeby;
  const { rinkeby: { pack }} = addresses;
  const linkContract: Contract = await ethers.getContractAt(LinkTokenABI, linkTokenAddress);

  // Fund pack contract.
  const amountToFund: BigNumber = ethers.utils.parseEther("1");
  const transferTx = await linkContract.connect(funder).transfer(pack, amountToFund);
  console.log("Transferring link: ", transferTx.hash);

  await transferTx.wait()
}
