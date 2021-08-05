import { run, ethers } from "hardhat";
import { Contract, ContractFactory } from 'ethers';
import { chainlinkVarsMumbai } from "../../utils/chainlink";

async function main() {
  await run("compile");

  console.log("Deploying to MUMBAI");

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // 1. Deploy ControlCenter
  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const controlCenter: Contract = await ProtocolControl_Factory.deploy(await deployer.getAddress());

  console.log(`ControlCenter.sol address: ${controlCenter.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });