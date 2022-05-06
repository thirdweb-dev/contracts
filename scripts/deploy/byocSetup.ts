import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWRegistry, ByocRegistry, ByocFactory } from "typechain";

/**
 *  NOTE: This deploy script is written for Polygon-Mumbai.
 *
 *  There is a mock `TWRegistry` deployed on Polygon-Mumbai for the purposes of Byoc testing.
 *
 *  This script does the following:
 *      (1) deploys `contracts/ByocRegistry` and `contracts/ByocFactory`.
 *      (2) grants `OPERATOR_ROLE` in `TWRegistry` to the deployed `ByocFactory`.
 *      (3) verifies deployed contracts.
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

  // const registryAddress: string = ethers.constants.AddressZero; // replace
  // const registry: TWRegistry = await ethers.getContractAt("TWRegistry", registryAddress);
  const registry: TWRegistry = await ethers.getContractFactory("TWRegistry").then(f => f.deploy(trustedForwarder));
  console.log("\nDeploying new TWRegistry \ntx: ", registry.deployTransaction.hash, "\naddress: ", registry.address);

  await registry.deployTransaction.wait();

  const byocRegsitry: ByocRegistry = await ethers
    .getContractFactory("ByocRegistry")
    .then(f => f.deploy(trustedForwarder));
  console.log(
    "Deploying ByocRegistry at tx: ",
    byocRegsitry.deployTransaction.hash,
    " address: ",
    byocRegsitry.address,
  );
  await byocRegsitry.deployTransaction.wait();
  console.log("Deployed ByocRegistry");

  const byocFactory: ByocFactory = await ethers
    .getContractFactory("ByocFactory")
    .then(f => f.deploy(registry.address, trustedForwarder));
  console.log("\nDeploying ByocFactory \ntx: ", byocFactory.deployTransaction.hash, "\naddress: ", byocFactory.address);
  await byocFactory.deployTransaction.wait();

  const tx = await registry.grantRole(await registry.OPERATOR_ROLE(), byocFactory.address);
  console.log("\nGranting operator role to ByocFactory: ", tx.hash);

  await tx.wait();

  console.log("\nDone. Now verifying contracts:");

  // await verify(byocRegsitry.address, [trustedForwarders]);
  await verify(byocFactory.address, [registry.address, trustedForwarder]);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
