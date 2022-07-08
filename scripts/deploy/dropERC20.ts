import hre, { ethers } from "hardhat";

import { DropERC20 } from "typechain";

async function main() {

  const dropERC20: DropERC20 = await ethers.getContractFactory("DropERC20").then(f => f.deploy());

  console.log(
    "Deploying DropERC20 \ntransaction: ",
    dropERC20.deployTransaction.hash,
    "\naddress: ",
    dropERC20.address,
  );

  await dropERC20.deployTransaction.wait();

  console.log("\n");

  console.log("Verifying contract.");
  await verify(dropERC20.address, []);
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
