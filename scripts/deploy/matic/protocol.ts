import { run, ethers } from "hardhat";
import { Contract, ContractFactory, BytesLike } from 'ethers';
import { chainlinkVarsMatic } from "../../../utils/chainlink";

async function main() {
  await run("compile");

  console.log("\n");

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // // 1. Deploy ControlCenter
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMatic;

  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const controlCenter: Contract = await ProtocolControl_Factory.deploy(
    "$PACK Protocol",
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees
  )

  console.log(
    "ProtocolControl.sol deployed at: ",
    controlCenter.address
  );

  const PACK: BytesLike = await controlCenter.PACK();
  const packAddress: string = await controlCenter.modules(PACK);
  console.log("Pack.sol is deployed at: ", packAddress);

  const MARKET: BytesLike = await controlCenter.MARKET();
  const marketAddress: string = await controlCenter.modules(MARKET);
  console.log("Market.sol is deployed at: ", marketAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });