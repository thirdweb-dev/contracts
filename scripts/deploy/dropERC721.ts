import hre, { ethers } from "hardhat";

import { DropERC721 } from "typechain";

async function main() {

  const dropERC721: DropERC721 = await ethers.getContractFactory("DropERC721").then(f => f.deploy());

  console.log(
    "Deploying DropERC721 \ntransaction: ",
    dropERC721.deployTransaction.hash,
    "\naddress: ",
    dropERC721.address,
  );

  await dropERC721.deployTransaction.wait();

  console.log("\n");

  console.log("Verifying contract.");
  await verify(dropERC721.address, []);
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
