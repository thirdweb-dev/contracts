import { run, ethers } from "hardhat";
import { Contract, ContractFactory } from 'ethers';
import { chainlinkVarsRinkeby } from "../../utils/chainlink";
import { rinkebyPairs } from "../../utils/ammPairs";

async function main() {
  await run("compile");

  const manualGasLimit: number = 5000000; // 5 million.

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // 1. Deploy ControlCenter
  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const controlCenter: Contract = await ProtocolControl_Factory.deploy(await deployer.getAddress(), { gasLimit: manualGasLimit });

  console.log(`ControlCenter.sol address: ${controlCenter.address}`);

//   2. Deploy rest of the protocol modules.
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(controlCenter.address, "$PACK Protocol", { gasLimit: manualGasLimit });

  console.log(`Pack.sol address: ${pack.address}`);

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(controlCenter.address, { gasLimit: manualGasLimit });

  console.log(`Market.sol address: ${market.address}`);

  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVarsRinkeby;
  
  const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
  const rng: Contract = await RNG_Factory.deploy(
    controlCenter.address,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees, 
    { gasLimit: manualGasLimit }
  );

  console.log(`RNG.sol address: ${rng.address}`);
  
  // Deploy Access Packs.
  const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
  const rewards: Contract = await Rewards_Factory.deploy({ gasLimit: manualGasLimit });

  console.log(`Rewards.sol address: ${rewards.address}`);

  console.log("\n");

//   Initialize $PACK Protocol in ControlCenter
  await controlCenter.connect(deployer).initPackProtocol(
    pack.address,
    market.address,
    rng.address,
    { gasLimit: manualGasLimit }
  );
  console.log("Initialized $PACK Protocol.")

//   Setup RNG
  for(let pair of rinkebyPairs) {
    await rng.connect(deployer).addPair(pair.pair, { gasLimit: manualGasLimit });
  }
  console.log("Initialized DEX RNG.")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });