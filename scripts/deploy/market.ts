import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory, Bytes } from "ethers";

import addresses from "../../utils/address.json";
import { getTxOptions } from "../../utils/txOptions";
import { getContractAddress } from "../../utils/contracts";

import * as fs from "fs";
import * as path from "path";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer and chainId
  const [deployer] = await ethers.getSigners();
  const chainId: number = await deployer.getChainId();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to chain: ${chainId}`);

  // Get `ProtocolControl.sol` contract + tx option
  const protocolControlAddr: string = (await getContractAddress("protocolControl", chainId)) as string;
  const protocolControl: Contract = await ethers.getContractAt("ProtocolControl", protocolControlAddr);

  const txOption = await getTxOptions(chainId);

  // Deploy Market.sol
  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(protocolControl.address, txOption);

  console.log("Market.sol deployed at: ", market.address);

  // Update module in `ProtocolControl`
  const moduleId: Bytes = await protocolControl.MARKET();
  const updateTx = await protocolControl.updateModule(moduleId, market.address, txOption);

  console.log("Updating MARKET module in ProtocolControl: ", updateTx.hash);

  await updateTx.wait();

  // Update contract addresses in `/utils`
  const networkName: string = hre.network.name.toLowerCase();
  const prevNetworkAddresses = addresses[networkName as keyof typeof addresses];

  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...prevNetworkAddresses,

      market: market.address,
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
