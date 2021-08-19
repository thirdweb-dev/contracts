import { ethers } from "hardhat";
import { BigNumber, Contract } from 'ethers';

import { chainlinkVars } from "../utils/chainlink";
import { addresses } from "../utils/contracts";

import LinkTokenABI from "../abi/LinkTokenInterface.json";

/**
 *  NOTE: set the right netowrk.
 *  
 *  Caller must have PROTOCOL_ADMIN role.
**/

// Enter the address of the contract you want to withdraw LINK from.
const prevPackAddr: string = ""

async function main(prevPackAddress: string): Promise<void> {
  const [protocolAdmin] = await ethers.getSigners();

  // Get `Pack` contract
  const relevantABI = [{
    "inputs": [
      {
        "internalType": "address",
        "name": "_to",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_amount",
        "type": "uint256"
      }
    ],
    "name": "transferLink",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }]
  const packContract: Contract = await ethers.getContractAt(relevantABI, prevPackAddress);

  // Get total LINK balance to transfer
  const { linkTokenAddress } = chainlinkVars.mumbai;
  const linkContract: Contract = await ethers.getContractAt(LinkTokenABI, linkTokenAddress);
  const amountToTransfer: BigNumber = await linkContract.balanceOf(prevPackAddress)

  // Transfer LINK to new pack contract.
  const { mumbai: { pack }} = addresses;
  const transferTx = await packContract.connect(protocolAdmin).transferLink(pack, amountToTransfer)

  await transferTx.wait()
}

main(prevPackAddr)
.then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })