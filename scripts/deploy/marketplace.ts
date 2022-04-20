import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { TWFactory } from "typechain/TWFactory";
import { Marketplace } from "typechain/Marketplace";

async function main() {

    const [caller]: SignerWithAddress[] = await ethers.getSigners();
    
    const nativeTokenWrapperAddress: string = ethers.constants.AddressZero; // replace
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
    const marketplace: Marketplace = await ethers.getContractFactory("Marketplace").then(f => f.deploy(nativeTokenWrapperAddress, twFeeAddress));

    console.log("Deploying Marketplace \ntransaction: ", marketplace.deployTransaction.hash, "\naddress: ", marketplace.address);

    console.log("\n")
    
    const addImplementationTx = await twFactory.addImplementation(marketplace.address)
    console.log("Adding Marketplace implementation to TWFactory: ", addImplementationTx.hash);
    await addImplementationTx.wait();

    console.log("\n")

    console.log("Verifying contract.")
    await verify(marketplace.address, [nativeTokenWrapperAddress, twFeeAddress]);
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