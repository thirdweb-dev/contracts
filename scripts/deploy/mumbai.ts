import { run, ethers } from "hardhat";
import { Contract, ContractFactory } from 'ethers';
import { chainlinkVarsMatic } from "../../utils/chainlink";

async function main() {
  await run("compile");

  console.log("Deploying to MUMBAI");

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // 1. Deploy ControlCenter
  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const controlCenter: Contract = await ProtocolControl_Factory.deploy(await deployer.getAddress());

  console.log(`ControlCenter.sol address: ${controlCenter.address}`);

  // 2. Deploy rest of the protocol modules.
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(controlCenter.address, "$PACK Protocol");

  console.log(`Pack.sol address: ${pack.address}`);

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(controlCenter.address);

  console.log(`Market.sol address: ${market.address}`);

  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsMatic;
  
  const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
  const rng: Contract = await RNG_Factory.deploy(
    controlCenter.address,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees
  );

  console.log(`RNG.sol address: ${rng.address}`);
  
  // Deploy Rewards contract.
  const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
  const rewards: Contract = await Rewards_Factory.deploy();

  console.log(`Rewards.sol address: ${rewards.address}`);

  console.log("\n");

  // Initialize $PACK Protocol in ControlCenter
  await controlCenter.connect(deployer).initPackProtocol(
    pack.address,
    market.address,
    rng.address
  );
  console.log("Initialized $PACK Protocol.")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });