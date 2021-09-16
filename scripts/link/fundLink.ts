import hre, { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";

import addresses from "../../utils/address.json";
import { chainlinkVars } from "../../utils/chainlink";

import LinkTokenABI from "../../abi/LinkTokenInterface.json";

/// NOTE: set the right netowrk.

async function main() {
  const [funder] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  console.log(`Funding with LINK on ${networkName} by account: ${await funder.getAddress()}`);

  // Get LINK contract
  const { linkTokenAddress } = chainlinkVars[networkName as keyof typeof chainlinkVars];
  const { pack: packAddress } = addresses[networkName as keyof typeof addresses];
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
