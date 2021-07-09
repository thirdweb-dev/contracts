import { run, ethers } from "hardhat";
import { Contract, ContractFactory } from 'ethers';
import { chainlinkVarsRinkeby } from "../../utils/chainlink";
import { rinkebyPairs } from "../../utils/ammPairs";

async function main() {
  await run("compile");

  const manualGasLimit: number = 5000000; // 5 million.

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`)

  // // 1. Deploy ControlCenter
  const ControlCenter_Factory: ContractFactory = await ethers.getContractFactory("ControlCenter");
  const controlCenter: Contract = await ControlCenter_Factory.deploy(await deployer.getAddress(), { gasLimit: manualGasLimit });

  console.log(`ControlCenter.sol address: ${controlCenter.address}`);

  // 2. Deploy rest of the protocol modules.
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(controlCenter.address, { gasLimit: manualGasLimit });

  console.log(`Pack.sol address: ${pack.address}`);

  const Handler_Factory: ContractFactory = await ethers.getContractFactory("Handler");
  const handler: Contract = await Handler_Factory.deploy(controlCenter.address, { gasLimit: manualGasLimit });

  console.log(`Handler.sol address: ${handler.address}`);

  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(controlCenter.address, { gasLimit: manualGasLimit });

  console.log(`Market.sol address: ${market.address}`);

  const { vrfCoordinator, linkTokenAddress, keyHash } = chainlinkVarsRinkeby;
  
  const RNG_Factory: ContractFactory = await ethers.getContractFactory("RNG");
  const rng: Contract = await RNG_Factory.deploy(
    controlCenter.address,
    vrfCoordinator,
    linkTokenAddress,
    keyHash, 
    { gasLimit: manualGasLimit }
  );

  console.log(`RNG.sol address: ${rng.address}`);

  const AssetSafe_Factory: ContractFactory = await ethers.getContractFactory("AssetSafe");
  const assetSafe: Contract = await AssetSafe_Factory.deploy(controlCenter.address, { gasLimit: manualGasLimit });

  console.log(`AssetSafe.sol address: ${assetSafe.address}`);
  
  // Deploy Access Packs.
  const AccessPacks_Factory: ContractFactory = await ethers.getContractFactory("AccessPacks");
  const accessPacks: Contract = await AccessPacks_Factory.deploy({ gasLimit: manualGasLimit });

  console.log(`AccessPacks.sol address: ${accessPacks.address}`);

  console.log("\n");

  // Initialize $PACK Protocol in ControlCenter
  await controlCenter.connect(deployer).initPackProtocol(
    pack.address,
    handler.address,
    market.address,
    rng.address,
    assetSafe.address, 
    { gasLimit: manualGasLimit }
  );
  console.log("Initialized $Pack Protocol.")

  // Setup RNG
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