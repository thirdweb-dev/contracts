import hre, { ethers } from "hardhat";
import { TWFactory } from "typechain/TWFactory";

/**
 *  Note: this script deploys a new instance of TWFactory + verifies it on block explorer.
 */

async function main() {

    console.log("\n")
    
    const forwarderAddress: string = ethers.constants.AddressZero; // replace
    const registryAddress: string = ethers.constants.AddressZero; // replace

    const twFactory: TWFactory = await ethers.getContractFactory("TWFactory").then(f => f.deploy(forwarderAddress, registryAddress));

    console.log("Deploying TWFactory \ntransaction: ", twFactory.deployTransaction.hash, "\naddress: ", twFactory.address);

    console.log("\n")

    console.log("Verifying contract.")
    await verify(twFactory.address, [forwarderAddress, registryAddress]);
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