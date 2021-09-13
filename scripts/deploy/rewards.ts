import { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import { getContractAddress } from "../../utils/contracts";
import { getTxOptions } from "../../utils/txOptions";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer and chainId
  const [deployer] = await ethers.getSigners();
  const chainId: number = await deployer.getChainId();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to chain: ${chainId}`);

  // Get `Pack.sol` address + tx option
  const packAddress: string = (await getContractAddress("pack", chainId) as string);
  const txOption = await getTxOptions(chainId);

  // Deploy Rewards.sol
  const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
  const rewards: Contract = await Rewards_Factory.deploy(packAddress, txOption);

  console.log("Rewards.sol deployed at: ", rewards.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
