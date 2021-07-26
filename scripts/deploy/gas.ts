import { run, ethers } from "hardhat";
import { Contract, ContractFactory } from 'ethers';
import { chainlinkVarsRinkeby } from "../../utils/chainlink";

async function main() {
  await run("compile");

  console.log("\n");

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // // 1. Deploy ControlCenter
  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const controlCenter: Contract = await ProtocolControl_Factory.deploy(await deployer.getAddress());

  console.log(
    "Estimated gas to deploy ControlCenter.sol: ",
    parseInt(controlCenter.deployTransaction.gasLimit.toString())
  );

  // 2. Deploy rest of the protocol modules.
  const packContractURI: string = "$PACK Protocol"; // Ideally - replace this with an IPFS URI 'ipfs://...' to the pack protocol logo.
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(controlCenter.address, packContractURI);

  console.log(
    "Estimated gas to deploy Pack.sol: ",
    parseInt(pack.deployTransaction.gasLimit.toString())
  );

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(controlCenter.address);

  console.log(
    "Estimated gas to deploy Market.sol: ",
    parseInt(market.deployTransaction.gasLimit.toString())
  );

  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsRinkeby;
  
  const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
  const rng: Contract = await RNG_Factory.deploy(
    controlCenter.address,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees
  );

  console.log(
    "Estimated gas to deploy RNG.sol: ",
    parseInt(rng.deployTransaction.gasLimit.toString())
  );
  
  // Deploy Rewards contract.
  const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
  const rewards: Contract = await Rewards_Factory.deploy();

  console.log(
    "Estimated gas to deploy Rewards.sol: ",
    parseInt(rewards.deployTransaction.gasLimit.toString())
  );

  console.log("\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });