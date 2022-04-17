import { ethers } from "hardhat";
import { TWFactory } from "typechain/TWFactory";

/**
 *  Note: this script deploys a new instance of TWFactory.
 */

async function main() {

    console.log("\n")
    
    const forwarderAddress: string = ethers.constants.AddressZero; // replace
    const registryAddress: string = ethers.constants.AddressZero; // replace

    const twFactory: TWFactory = await ethers.getContractFactory("TWFactory").then(f => f.deploy(forwarderAddress, registryAddress));

    console.log("Deploying TWFactory \ntransaction: ", twFactory.deployTransaction.hash, "\naddress: ", twFactory.address);

    console.log("\n")
}

main()
    .then(() => process.exit(0))
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })