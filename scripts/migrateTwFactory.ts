import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { TWFactory } from "typechain";

import contractTypes from "utils/contractTypes";
import { BytesLike } from "@ethersproject/bytes";

async function main() {
  const [caller]: SignerWithAddress[] = await ethers.getSigners();

  console.log("\nCaller address: ", caller.address);

  const currentTWFactoryAddress: string = ethers.constants.AddressZero; // replace
  const currentTWFactory: TWFactory = await ethers.getContractAt("TWFactory", currentTWFactoryAddress);

  const newTWFactoryAddress: string = ethers.constants.AddressZero; // replace
  const newTWFactory: TWFactory = await ethers.getContractAt("TWFactory", newTWFactoryAddress);

  console.log("\nCurrent factory: ", currentTWFactoryAddress, "\nNew factory: ", newTWFactoryAddress);

  const hasFactoryRole = await newTWFactory.hasRole(
    ethers.utils.solidityKeccak256(["string"], ["FACTORY_ROLE"]),
    caller.address,
  );
  if (!hasFactoryRole) {
    throw new Error("Caller does not have FACTORY_ROLE on new factory");
  }

  const migratedContractTypes: string[] = [];
  const nonMigratedContractTypes: string[] = [];

  for (const contractType of contractTypes) {
    console.log(`\nMigrating ${contractType}`);

    const contractTypeBytes: BytesLike = ethers.utils.formatBytes32String(contractType);

    const currentVersion: number = (await currentTWFactory.currentVersion(contractTypeBytes)).toNumber();
    if (currentVersion == 0) {
      console.log(`No current implementation available for ${contractType}`);
      nonMigratedContractTypes.push(contractType);
      continue;
    }

    const implementation = await currentTWFactory.implementation(contractTypeBytes, currentVersion);
    const addImplementationTx = await newTWFactory.addImplementation(implementation);
    console.log(`Migrating implementation of ${contractType} at tx: `, addImplementationTx.hash);

    await addImplementationTx.wait();

    const implementationOnNewFactory = await newTWFactory.getLatestImplementation(contractTypeBytes);

    if (ethers.utils.getAddress(implementationOnNewFactory) != ethers.utils.getAddress(implementation)) {
      console.log("Something went wrong. Failed to migrate contract.");
      nonMigratedContractTypes.push(contractType);
    } else {
      migratedContractTypes.push(contractType);
      console.log("Done.");
    }
  }

  console.log(
    "\nMigration complete:\nMigrated contract types; ",
    migratedContractTypes,
    "\nDid not migrate: ",
    nonMigratedContractTypes,
  );
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
