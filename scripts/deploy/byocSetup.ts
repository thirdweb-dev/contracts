import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWRegistry, ContractMetadataRegistry, ContractDeployer, ContractPublisher } from "typechain";

/**
 *
 *  There is a mock `TWRegistry` deployed on testnets for the purposes of thirdweb deploy testing.
 *
 *  This script does the following:
 *      (1) deploys `contracts/ContractMetadataRegistry` and `contracts/ContractDeployer`.
 *      (2) grants `OPERATOR_ROLE` in `TWRegistry` to the deployed `ContractDeployer`.
 *      (3) grants `OPERATOR_ROLE` in `ContractMetadataRegistry` to the deployed `ContractDeployer`.
 *      (4) verifies deployed contracts.
 */

async function verify(address: string, args: any[]) {
  try {
    return await hre.run("verify:verify", {
      address: address,
      constructorArguments: args,
    });
  } catch (e) {
    console.log(address, args, e);
  }
}

async function main() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  console.log("Deployer address:", deployer.address);

  const trustedForwarder: string = "0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81";

  const registryAddress: string = ethers.constants.AddressZero; // REPLACE FOR CORRECT CHAIN
  const registry: TWRegistry = await ethers.getContractAt("TWRegistry", registryAddress);

  const contractMetadataRegistry: ContractMetadataRegistry = await ethers
    .getContractFactory("ContractMetadataRegistry")
    .then(f => f.deploy(trustedForwarder));
  console.log(
    "Deploying ContractMetadataRegistry at tx: ",
    contractMetadataRegistry.deployTransaction.hash,
    " address: ",
    contractMetadataRegistry.address,
  );
  await contractMetadataRegistry.deployTransaction.wait();
  console.log("Deployed ContractMetadataRegistry");

  const contractPublisher: ContractPublisher = await ethers
    .getContractFactory("ContractPublisher")
    .then(f => f.deploy(trustedForwarder));
  console.log(
    "Deploying ContractPublisher at tx: ",
    contractPublisher.deployTransaction.hash,
    " address: ",
    contractPublisher.address,
  );
  await contractPublisher.deployTransaction.wait();
  console.log("Deployed ContractPublisher");

  const contractDeployer: ContractDeployer = await ethers
    .getContractFactory("ContractDeployer")
    .then(f => f.deploy(registry.address, contractMetadataRegistry.address, trustedForwarder));
  console.log(
    "\nDeploying ContractDeployer \ntx: ",
    contractDeployer.deployTransaction.hash,
    "\naddress: ",
    contractDeployer.address,
  );
  await contractDeployer.deployTransaction.wait();

  const tx = await registry.grantRole(await registry.OPERATOR_ROLE(), contractDeployer.address);
  console.log("\nGranting operator role to ContractDeployer for TWRegistry: ", tx.hash);
  await tx.wait();
  const tx2 = await contractMetadataRegistry.grantRole(await registry.OPERATOR_ROLE(), contractDeployer.address);
  console.log("\nGranting operator role to ContractDeployer for ContractMetadataRegistry: ", tx.hash);
  await tx2.wait();

  console.log("\nDone. Now verifying contracts:");

  await verify(contractPublisher.address, [trustedForwarder]);
  await verify(contractMetadataRegistry.address, [trustedForwarder]);
  await verify(contractDeployer.address, [registry.address, contractMetadataRegistry.address, trustedForwarder]);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
