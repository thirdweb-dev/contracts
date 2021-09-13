import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";

import { getChainlinkVars, ChainlinkVars } from "../utils/chainlink";
import { getContractAddress } from "../utils/contracts";

import LinkTokenABI from "../abi/LinkTokenInterface.json";

// Enter the address of the contract you want to withdraw LINK from.
const prevPackAddr: string = "";

async function main(prevPackAddress: string): Promise<void> {
  const [protocolAdmin] = await ethers.getSigners();
  const chainId: number = await protocolAdmin.getChainId();

  console.log(`Moving with LINK on chain: ${chainId} by account: ${await protocolAdmin.getAddress()}`);

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
  const { linkTokenAddress } = (await getChainlinkVars(chainId)) as ChainlinkVars;
  const linkContract: Contract = await ethers.getContractAt(LinkTokenABI, linkTokenAddress as string);
  const amountToTransfer: BigNumber = await linkContract.balanceOf(prevPackAddress);

  // Transfer LINK to new pack contract.
  const packAddress = await getContractAddress("pack", chainId);
  const transferTx = await packContract.connect(protocolAdmin).transferLink(packAddress, amountToTransfer);

  await transferTx.wait();
}

main(prevPackAddr)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
