import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { SignatureDrop } from "typechain";

async function main() {

    const [caller]: SignerWithAddress[] = await ethers.getSigners();

    console.log("\n")

    const sigdrop: SignatureDrop = await ethers.getContractFactory("SignatureDrop").then(f => f.deploy());
    console.log("Deploying SignatureDrop \ntransaction: ", sigdrop.deployTransaction.hash, "\naddress: ", sigdrop.address);
    await sigdrop.deployTransaction.wait();

    console.log("\n")

    console.log("Verifying contract.")
    await verify(sigdrop.address, []);
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
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })