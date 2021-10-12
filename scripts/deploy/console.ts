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

  console.log(
    `Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}. Treasury: ${providerTreasury}`,
  );

  // Deploy Forwarder
  const Forwarder_Factory: ContractFactory = await ethers.getContractFactory("Forwarder");
  const forwarder: Contract = await Forwarder_Factory.deploy();
  await forwarder.deployed();
  console.log(`Deploying Forwarder: ${forwarder.address} at tx hash: ${forwarder.deployTransaction.hash}`);

  // Deploy ControlDeployer
  const ControlDeployer_Factory: ContractFactory = await ethers.getContractFactory("ControlDeployer");
  const controlDeployer: Contract = await ControlDeployer_Factory.deploy();
  await controlDeployer.deployed();
  console.log(
    `Deploying ControlDeployer: ${controlDeployer.address} at tx hash: ${controlDeployer.deployTransaction.hash}`,
  );

  // Deploy Registry
  const Registry_Factory: ContractFactory = await ethers.getContractFactory("Registry");
  const registry: Contract = await Registry_Factory.deploy(
    providerTreasury,
    forwarder.address,
    controlDeployer.address,
  );
  await registry.deployed();

  console.log(`Deploying Registry: ${registry.address} at tx hash: ${registry.deployTransaction.hash}`);

  const registryRole = await controlDeployer.REGISTRY_ROLE();
  const tx = await controlDeployer.grantRole(registryRole, registry.address);
  await tx.wait();
  console.log(`Granted Role to Registry on Deployer at tx hash: ${tx.hash}`);

  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...currentNetworkAddresses,
      controlDeployer: controlDeployer.address,
      registry: registry.address,
      forwarder: forwarder.address,
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
