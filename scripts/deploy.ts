import { run, ethers } from "hardhat";
import { BigNumber, Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { chainlinkVars, getChainlinkVars } from "../../../utils/chainlink";

async function main() {
  await run("compile");

  console.log("\n");

  const manualGasPrice: BigNumber = ethers.utils.parseUnits("5", "gwei");
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  const chainId: number = await deployer.getChainId();
  console.log("ChainId: ", chainId);

  const chainlink = await getChainlinkVars(chainId);
  console.log("Chainlink vars: ", chainlink);

  console.log(`Deploying contracts with account: ${await deployer.getAddress()}`);

  // Deploy ProtocolControl
  //   const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars.mumbai;

  //   const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  //   const controlCenter: Contract = await ProtocolControl_Factory.deploy({
  //     gasPrice: manualGasPrice,
  //   });

  //   console.log("ProtocolControl.sol deployed at: ", controlCenter.address);

  //   // Deploy Pack
  //   const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  //   const pack: Contract = await Pack_Factory.deploy(
  //     controlCenter.address,
  //     "$PACK Protocol",
  //     vrfCoordinator,
  //     linkTokenAddress,
  //     keyHash,
  //     fees,
  //     { gasPrice: manualGasPrice },
  //   );

  //   console.log("Pack.sol is deployed at: ", pack.address);

  //   // Deploy Market
  //   const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  //   const market: Contract = await Market_Factory.deploy(controlCenter.address, { gasPrice: manualGasPrice });

  //   console.log("Market.sol is deployed at: ", market.address);

  //   // Initialize protocol
  //   const initTx = await controlCenter.initializeProtocol(pack.address, market.address, { gasPrice: manualGasPrice });
  //   console.log("Initializing protocol: ", initTx.hash);
  //   await initTx.wait();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
