import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWRegistry } from "typechain/TWRegistry";
import { ByocRegistry } from "typechain/ByocRegistry";
import { ByocFactory } from "typechain/ByocFactory";

/**
 *  NOTE: This deploy script is written for Polygon-Mumbai.
 * 
 *  There is a mock `TWRegistry` deployed on Polygon-Mumbai for the purposes of Byoc testing.
 * 
 *  This script does the following:
 *      (1) deploys `contracts/ByocRegistry` and `contracts/ByocFactory`.
 *      (2) grants `OPERATOR_ROLE` in `TWRegistry` to the deployed `ByocFactory`.
 *      (3) verifies deployed contracts.
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

    const registryAddress: string = "0x3F17972CB27506eb4a6a3D59659e0B57a43fd16C";

    const [deployer]: SignerWithAddress[] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);

    const trustedForwarders: string[] = ["0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81"];

    const registry: TWRegistry = await ethers.getContractAt("TWRegistry", registryAddress);
    console.log("TWRegistry at: ", registry.address);

    // const byocRegsitry: ByocRegistry = await ethers.getContractFactory("ByocRegistry").then(f => f.deploy(
    //     trustedForwarders
    // ));
    // console.log("Deploying ByocRegistry at tx: ", byocRegsitry.deployTransaction.hash, " address: ", byocRegsitry.address);
    // await byocRegsitry.deployTransaction.wait();
    // console.log("Deployed ByocRegistry")

    const byocFactory: ByocFactory = await ethers.getContractFactory("ByocFactory").then(f => f.deploy(
        registryAddress,
        trustedForwarders
    ));
    console.log("Deploying ByocFactory at tx: ", byocFactory.deployTransaction.hash, " address: ", byocFactory.address);
    await byocFactory.deployTransaction.wait();
    console.log("Deployed ByocFactory")

    const tx = await registry.grantRole(
        await registry.OPERATOR_ROLE(),
        byocFactory.address
    );
    console.log("Granting operator role to ByocFactory: ", tx.hash);

    await tx.wait();

    console.log("Done. Now verifying contracts:");

    // await verify(byocRegsitry.address, [trustedForwarders]);
    await verify(byocFactory.address, [registryAddress, trustedForwarders]);
}

main()
    .then(() => process.exit(0))
    .catch((e) => {
        console.error(e);
        process.exit(1)
    })