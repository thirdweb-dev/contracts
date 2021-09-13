import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

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

  // Get `Pack.sol` address + tx option
  const packAddress: string = (await getContractAddress("pack", chainId)) as string;
  const txOption = await getTxOptions(chainId);

  // Deploy Rewards.sol
  const Rewards_Factory: ContractFactory = await ethers.getContractFactory("Rewards");
  const rewards: Contract = await Rewards_Factory.deploy(packAddress, txOption);

  console.log("Rewards.sol deployed at: ", rewards.address);

  // Update contract addresses in `/utils`
  const networkName: string = hre.network.name.toLowerCase();
  const prevNetworkAddresses = addresses[networkName as keyof typeof addresses];

  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...prevNetworkAddresses,

      rewards: rewards.address,
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
