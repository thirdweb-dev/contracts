import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory, Bytes } from "ethers";

import addresses from "../../utils/address.json";
import { getTxOptions } from "../../utils/txOptions";
import { getContractAddress } from "../../utils/contracts";
import { getChainlinkVars, ChainlinkVars } from "../../utils/chainlink";

import * as fs from "fs";
import * as path from "path";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer and chainId
  const [deployer] = await ethers.getSigners();
  const chainId: number = await deployer.getChainId();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to chain: ${chainId}`);

  // Get `ProtocolControl.sol` contract + chainlink vars + tx option
  const protocolControlAddr: string = (await getContractAddress("protocolControl", chainId)) as string;
  const protocolControl: Contract = await ethers.getContractAt("ProtocolControl", protocolControlAddr);

  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = (await getChainlinkVars(chainId)) as ChainlinkVars;

  const txOption = await getTxOptions(chainId);

  // Deploy Pack.sol
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(
    protocolControl.address,
    "$PACK Protocol",
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    txOption,
  );

  console.log("Pack.sol deployed at: ", pack.address);

  // Update module in `ProtocolControl`
  const moduleId: Bytes = await protocolControl.PACK();
  const updateTx = await protocolControl.updateModule(moduleId, pack.address, txOption);

  console.log("Updating PACK module in ProtocolControl: ", updateTx.hash);

  await updateTx.wait();

  // Update contract addresses in `/utils`
  const networkName: string = hre.network.name.toLowerCase();
  const prevNetworkAddresses = addresses[networkName as keyof typeof addresses];

  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...prevNetworkAddresses,

      pack: pack.address,
    },
  };

  fs.writeFileSync(path.join(__dirname, "../../utils/address.json"), JSON.stringify(updatedAddresses));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
