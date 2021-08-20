import { run, ethers } from "hardhat";
import { BigNumber, Contract, ContractFactory } from 'ethers';

async function main() {
  await run("compile");

  console.log("\n");

  const manualGasPrice: BigNumber = ethers.utils.parseUnits("5", "gwei");
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // Deploy Rewards.sol
  const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
  const rewards: Contract = await Rewards_Factory.deploy({
      gasPrice: manualGasPrice
  })

  console.log(
    "Rewards.sol deployed at: ",
    rewards.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });