import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWFactory, DropERC1155 } from "typechain";

async function main() {
  const [caller]: SignerWithAddress[] = await ethers.getSigners();
  
  const dropERC1155: DropERC1155 = await ethers.getContractFactory("DropERC1155").then(f => f.deploy());
  console.log(
    "Deploying DropERC1155 \ntransaction: ",
    dropERC1155.deployTransaction.hash,
    "\naddress: ",
    dropERC1155.address,
  );

  await dropERC1155.deployTransaction.wait();

  console.log("\n");

  console.log("Verifying contract.");
  await verify(dropERC1155.address, []);
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
