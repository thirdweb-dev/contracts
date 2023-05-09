import hre, { ethers } from "hardhat";

import { AccountFactory } from "typechain";

async function main() {

  const entrypointAddress = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"
  const accountFactory: AccountFactory = await ethers.getContractFactory("AccountFactory").then(f => f.deploy(entrypointAddress));

  console.log(
    "Deploying AccountFactory \ntransaction: ",
    accountFactory.deployTransaction.hash,
    "\naddress: ",
    accountFactory.address,
  );

  await accountFactory.deployTransaction.wait();

  console.log("\n");

  console.log("Verifying contract.");
  await verify(accountFactory.address, [entrypointAddress]);
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
