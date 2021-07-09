import { run, ethers } from "hardhat";
import { Contract, ContractFactory } from 'ethers';
import { chainlinkVarsRinkeby } from "../../utils/chainlink";
import { rinkebyPairs } from "../../utils/ammPairs";

async function main() {
  await run("compile");

  console.log("\n");

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // // 1. Deploy ControlCenter
  const ControlCenter_Factory: ContractFactory = await ethers.getContractFactory("ControlCenter");
  const controlCenter: Contract = await ControlCenter_Factory.deploy(await deployer.getAddress());

  console.log(
    "Estimated gas to deploy ControlCenter.sol: ",
    parseInt(controlCenter.deployTransaction.gasLimit.toString())
  );

  // 2. Deploy rest of the protocol modules.
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(controlCenter.address);

  console.log(
    "Estimated gas to deploy Pack.sol: ",
    parseInt(pack.deployTransaction.gasLimit.toString())
  );

  const Handler_Factory: ContractFactory = await ethers.getContractFactory("Handler");
  const handler: Contract = await Handler_Factory.deploy(controlCenter.address);

  console.log(
    "Estimated gas to deploy Handler.sol: ",
    parseInt(handler.deployTransaction.gasLimit.toString())
  );

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(controlCenter.address);

  console.log(
    "Estimated gas to deploy Market.sol: ",
    parseInt(market.deployTransaction.gasLimit.toString())
  );

  const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVarsRinkeby;
  
  const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
  const rng: Contract = await RNG_Factory.deploy(
    controlCenter.address,
    vrfCoordinator,
    linkTokenAddress,
    keyHash
  );

  console.log(
    "Estimated gas to deploy RNG.sol: ",
    parseInt(rng.deployTransaction.gasLimit.toString())
  );

  const AssetSafe_Factory: ContractFactory = await ethers.getContractFactory("AssetSafe");
  const assetSafe: Contract = await AssetSafe_Factory.deploy(controlCenter.address);

  console.log(
    "Estimated gas to deploy AssetSafe.sol: ",
    parseInt(assetSafe.deployTransaction.gasLimit.toString())
  );
  
  // Deploy Access Packs.
  const AccessPacks_Factory: ContractFactory = await ethers.getContractFactory("AccessPacks");
  const accessPacks: Contract = await AccessPacks_Factory.deploy();

  console.log(
    "Estimated gas to deploy AccessPacks.sol: ",
    parseInt(accessPacks.deployTransaction.gasLimit.toString())
  );

  console.log("\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });