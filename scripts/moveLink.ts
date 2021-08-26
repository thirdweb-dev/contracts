import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";

import { chainlinkVars } from "../utils/chainlink";
import { addresses } from "../utils/contracts";

import LinkTokenABI from "../abi/LinkTokenInterface.json";

/**
 *  NOTE: set the right netowrk.
 *
 *  Caller must have PROTOCOL_ADMIN role.
 **/

// Enter the address of the contract you want to withdraw LINK from.
const prevPackAddr: string = "0x3d5a51975fD29E45Eb285349F12b77b4c153c8e0";

async function main(prevPackAddress: string): Promise<void> {
  const [protocolAdmin] = await ethers.getSigners();

  // Get `Pack` contract
  const relevantABI = [
    {
      inputs: [
        {
          internalType: "address",
          name: "_to",
          type: "address",
        },
        {
          internalType: "uint256",
          name: "_amount",
          type: "uint256",
        },
      ],
      name: "transferLink",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
  ];
  const packContract: Contract = await ethers.getContractAt(relevantABI, prevPackAddress);

  // Get total LINK balance to transfer
  const { linkTokenAddress } = chainlinkVars.matic;
  const linkContract: Contract = await ethers.getContractAt(LinkTokenABI, linkTokenAddress);
  const amountToTransfer: BigNumber = await linkContract.balanceOf(prevPackAddress);

  // Transfer LINK to new pack contract.
  //const { matic: { pack }} = addresses;
  const to = "0xd451D7C340f84a0B57b0923C1bD931F6447c75A6";
  const transferTx = await packContract.connect(protocolAdmin).transferLink(to, amountToTransfer);

  await transferTx.wait();
}

main(prevPackAddr)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

