import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWFactory } from "typechain/TWFactory";
import { DropERC20 } from "typechain/DropERC20";

async function main() {

    const [caller]: SignerWithAddress[] = await ethers.getSigners();
    
    const twFeeAddress: string = ethers.constants.AddressZero; // replace
    const twFactoryAddress: string = ethers.constants.AddressZero; // replace
    
    const twFactory: TWFactory = await ethers.getContractAt('TWFactory', twFactoryAddress);
    
    const hasFactoryRole = await twFactory.hasRole(
        ethers.utils.solidityKeccak256(["string"], ["FACTORY_ROLE"]),
        caller.address
    )
    if(!hasFactoryRole) {
        throw new Error("Caller does not have FACTORY_ROLE on factory");
    }
    const dropERC20: DropERC20 = await ethers.getContractFactory("DropERC20").then(f => f.deploy(twFeeAddress));

    console.log("Deploying DropERC20 \ntransaction: ", dropERC20.deployTransaction.hash, "\naddress: ", dropERC20.address);

    console.log("\n")
    
    const addImplementationTx = await twFactory.addImplementation(dropERC20.address)
    console.log("Adding DropERC20 implementation to TWFactory: ", addImplementationTx.hash);
    await addImplementationTx.wait();

    console.log("\n")

    console.log("Verifying contract.")
    await verify(dropERC20.address, [twFeeAddress]);
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