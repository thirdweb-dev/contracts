import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { TWFactory } from "typechain";
import { txOptions } from "utils/txOptions";

async function main() {
  const [caller]: SignerWithAddress[] = await ethers.getSigners();

  console.log("\nCaller address: ", caller.address);

  const twFactoryAddress: string = "0x97EA0Fcc552D5A8Fb5e9101316AAd0D62Ea0876B"; // replace
  const twFactory: TWFactory = await ethers.getContractAt("TWFactory", twFactoryAddress);

  const hasFactoryRole = await twFactory.hasRole(
    ethers.utils.solidityKeccak256(["string"], ["FACTORY_ROLE"]),
    caller.address,
  );
  if (!hasFactoryRole) {
    throw new Error("Caller does not have FACTORY_ROLE on new factory");
  }

  // const implementations: string[] = []; // replace
  // const data = implementations.map((impl) => twFactory.interface.encodeFunctionData("addImplementation", [impl]));

  // const tx = await twFactory.multicall(data);
  const tx = await twFactory.approveImplementation("0x664244560eBa21Bf82d7150C791bE1AbcD5B4cd7", true);
  console.log("Approving implementations: ", tx.hash);

  await tx.wait();

  console.log("Done.");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
