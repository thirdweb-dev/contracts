import hre, { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";

import addresses from "../../utils/address.json";
import { chainlinkVars } from "../../utils/chainlink";

import LinkTokenABI from "../../abi/LinkTokenInterface.json";

// Enter the address of the contract you want to withdraw LINK from.
const prevPackAddr: string = "";

async function main(prevPackAddress: string): Promise<void> {
  const [protocolAdmin] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  console.log(`Moving with LINK on ${networkName} by account: ${await protocolAdmin.getAddress()}`);

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
  const { linkTokenAddress } = chainlinkVars[networkName as keyof typeof chainlinkVars];
  const linkContract: Contract = await ethers.getContractAt(LinkTokenABI, linkTokenAddress as string);
  const amountToTransfer: BigNumber = await linkContract.balanceOf(prevPackAddress);

  // Transfer LINK to new pack contract.
  const { pack: packAddress } = addresses[networkName as keyof typeof addresses];
  const transferTx = await packContract.connect(protocolAdmin).transferLink(packAddress, amountToTransfer);

  await transferTx.wait();
}

main(prevPackAddr)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
