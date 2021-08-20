import { run, ethers } from "hardhat";
import { BigNumber, Contract, ContractFactory } from 'ethers';
import { addresses } from "../../../utils/contracts";

async function main() {
  await run("compile");

  console.log("\n");

  const packAddress: string = addresses.mumbai.pack

  const manualGasPrice: BigNumber = ethers.utils.parseUnits("5", "gwei");
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // Deploy Rewards.sol
  const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
  const rewards: Contract = await Rewards_Factory.deploy(packAddress, { gasPrice: manualGasPrice })

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