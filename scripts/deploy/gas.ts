import { run, ethers } from "hardhat";
import { Contract, ContractFactory, BigNumber } from 'ethers';
import { chainlinkVarsMumbai } from "../../utils/chainlink";

async function main() {
  await run("compile");

  console.log("\n");

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // // 1. Deploy ControlCenter
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMumbai;

  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const controlCenter: Contract = await ProtocolControl_Factory.deploy(
    "$PACK Protocol",
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees
  )

  console.log(
    "Estimated gas to deploy ControlCenter.sol: ",
    parseInt(controlCenter.deployTransaction.gasLimit.toString())
  );

  // // 2. Initialize protocol's ERC 1155 pack token.
  // const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMumbai;

  // const gasForPack: BigNumber = await controlCenter.estimateGas.initializePack(
  //   "$PACK Protocol",
  //   vrfCoordinator,
  //   linkTokenAddress,
  //   keyHash,
  //   fees
  // )
  // console.log("Est. gas to initialize Pack: ", parseInt(gasForPack.toString()))
  
  // // 3. Initialize protocol's market for packs and rewards.
  // const gasForMarket: BigNumber = await controlCenter.estimateGas.initializeMarket();
  // console.log("Est. gas to initialize Market: ", parseInt(gasForMarket.toString())) 
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });