import { run, ethers } from "hardhat";
import { BigNumber, BytesLike, Contract, ContractFactory } from 'ethers';
import { chainlinkVarsMumbai } from "../../../utils/chainlink";

async function main() {
  await run("compile");

  console.log("\n");

  const manualGasPrice: BigNumber = ethers.utils.parseEther("0.000000005");

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
    fees,
    {
      gasPrice: manualGasPrice
    }
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