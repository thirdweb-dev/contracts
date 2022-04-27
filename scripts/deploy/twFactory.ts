import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWFactory, TWRegistry } from "typechain";

/**
 *  Note: this script deploys a new instance of TWFactory + verifies it on block explorer.
 */

async function main() {
  const [caller]: SignerWithAddress[] = await ethers.getSigners();

  console.log("\nCaller address: ", caller.address);
  console.log("\n");

  const forwarderAddress: string = ethers.constants.AddressZero; // replace
  const registryAddress: string = ethers.constants.AddressZero; // replace

  const twRegistry: TWRegistry = await ethers.getContractAt("TWRegistry", registryAddress);

  const isAdminOnRegistry: boolean = await twRegistry.hasRole(
    ethers.utils.solidityKeccak256(["string"], ["DEFAULT_ADMIN_ROLE"]),
    caller.address,
  );
  if (!isAdminOnRegistry) {
    throw new Error("Caller not admin on registry");
  }

  const twFactory: TWFactory = await ethers
    .getContractFactory("TWFactory")
    .then(f => f.deploy(forwarderAddress, registryAddress));

  console.log(
    "Deploying TWFactory \ntransaction: ",
    twFactory.deployTransaction.hash,
    "\naddress: ",
    twFactory.address,
  );

  console.log("\n");

  const grantRoleTx = await twRegistry.grantRole(
    ethers.utils.solidityKeccak256(["string"], ["OPERATOR_ROLE"]),
    twFactory.address,
  );
  console.log("Granting OPERATOR_ROLE to factory on registry at tx: ", grantRoleTx.hash);
  await grantRoleTx.wait();

  console.log("Verifying contract.");
  await verify(twFactory.address, [forwarderAddress, registryAddress]);
}

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

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
