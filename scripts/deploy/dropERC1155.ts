import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWFactory, DropERC1155 } from "typechain";

async function main() {
  const [caller]: SignerWithAddress[] = await ethers.getSigners();

  // const twFeeAddress: string = "0x8c4b615040ebd2618e8fc3b20cefe9abafdeb0ea"; // replace
  const twFactoryAddress: string = "0x5DBC7B840baa9daBcBe9D2492E45D7244B54A2A0"; // replace

  const twFactory: TWFactory = await ethers.getContractAt("TWFactory", twFactoryAddress);

  const hasFactoryRole = await twFactory.hasRole(
    ethers.utils.solidityKeccak256(["string"], ["FACTORY_ROLE"]),
    caller.address,
  );
  if (!hasFactoryRole) {
    throw new Error("Caller does not have FACTORY_ROLE on factory");
  }
  const dropERC1155: DropERC1155 = await ethers.getContractFactory("DropERC1155").then(f => f.deploy());

  console.log(
    "Deploying DropERC1155 \ntransaction: ",
    dropERC1155.deployTransaction.hash,
    "\naddress: ",
    dropERC1155.address,
  );

  await dropERC1155.deployTransaction.wait();

  console.log("\n");

  const addImplementationTx = await twFactory.addImplementation(dropERC1155.address);
  console.log("Adding DropERC1155 implementation to TWFactory: ", addImplementationTx.hash);
  await addImplementationTx.wait();

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
