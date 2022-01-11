import hre, { ethers } from "hardhat";

// Types
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import addresses from "../../utils/addresses/console.json";
import * as fs from "fs";
import * as path from "path";

// Utils
async function main(): Promise<void> {
  // Get deployer
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  const networkName: string = hre.network.name;
  const currentNetworkAddresses = addresses[networkName as keyof typeof addresses];
  const providerTreasury = currentNetworkAddresses.treasury;
  const registryAddress = currentNetworkAddresses.registry;

  console.log(
    `Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}. Treasury: ${providerTreasury}`,
  );

  // Deploy Registry
  const registry = await ethers.getContractAt("Registry", registryAddress);

  // Deploy ControlDeployer
  const ControlDeployer_Factory: ContractFactory = await ethers.getContractFactory("ControlDeployer");
  const controlDeployer: Contract = await ControlDeployer_Factory.deploy();
  await controlDeployer.deployed();
  console.log(
    `Deploying ControlDeployer: ${controlDeployer.address} at tx hash: ${controlDeployer.deployTransaction.hash}`,
  );

  const registryRole = await controlDeployer.REGISTRY_ROLE();
  const tx = await controlDeployer.grantRole(registryRole, registry.address);
  await tx.wait();
  console.log(`Granted Role to Registry on Deployer at tx hash: ${tx.hash}`);

  const tx2 = await registry.setDeployer(controlDeployer.address);
  await tx2.wait();
  console.log(`Set Deployer on Registry at tx hash: ${tx2.hash}`);

  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...currentNetworkAddresses,
      controlDeployer: controlDeployer.address,
    },
  };

  fs.writeFileSync(
    path.join(__dirname, "../../utils/addresses/console.json"),
    JSON.stringify(updatedAddresses, null, 2),
  );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
