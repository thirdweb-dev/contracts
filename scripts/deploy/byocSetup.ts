import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { ContractPublisher } from "typechain";

/**
 *
 * Deploys the contract publisher and verifies the contract.
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

  const contractPublisher: ContractPublisher = await ethers
    .getContractFactory("ContractPublisher")
    .then(f => f.deploy(trustedForwarder));
  console.log(
    "Deploying ContractPublisher at tx: ",
    contractPublisher.deployTransaction.hash,
    " address: ",
    contractPublisher.address,
  );
  await contractPublisher.deployTransaction.wait();
  console.log("Deployed ContractPublisher");

  console.log("\nDone. Now verifying contracts:");

  await verify(contractPublisher.address, [trustedForwarder]);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
