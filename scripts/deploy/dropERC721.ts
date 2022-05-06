import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWFactory, DropERC721 } from "typechain";

async function main() {
  const [caller]: SignerWithAddress[] = await ethers.getSigners();

  const twFeeAddress: string = ethers.constants.AddressZero; // replace
  const twFactoryAddress: string = ethers.constants.AddressZero; // replace

  const twFactory: TWFactory = await ethers.getContractAt("TWFactory", twFactoryAddress);

  const hasFactoryRole = await twFactory.hasRole(
    ethers.utils.solidityKeccak256(["string"], ["FACTORY_ROLE"]),
    caller.address,
  );
  if (!hasFactoryRole) {
    throw new Error("Caller does not have FACTORY_ROLE on factory");
  }
  const dropERC721: DropERC721 = await ethers.getContractFactory("DropERC721").then(f => f.deploy(twFeeAddress));

  console.log(
    "Deploying DropERC721 \ntransaction: ",
    dropERC721.deployTransaction.hash,
    "\naddress: ",
    dropERC721.address,
  );

  await dropERC721.deployTransaction.wait();

  console.log("\n");

  const addImplementationTx = await twFactory.addImplementation(dropERC721.address);
  console.log("Adding DropERC721 implementation to TWFactory: ", addImplementationTx.hash);
  await addImplementationTx.wait();

  console.log("\n");

  console.log("Verifying contract.");
  await verify(dropERC721.address, [twFeeAddress]);
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
