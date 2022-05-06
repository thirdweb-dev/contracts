import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { TWFactory } from "typechain/TWFactory";

async function main() {

    const [caller]: SignerWithAddress[] = await ethers.getSigners();

    console.log("\nCaller address: ", caller.address);

    const twFactoryAddress: string = ethers.constants.AddressZero; // replace
    const twFactory: TWFactory = await ethers.getContractAt("TWFactory", twFactoryAddress);

    const hasFactoryRole = await twFactory.hasRole(
        ethers.utils.solidityKeccak256(["string"], ["FACTORY_ROLE"]),
        caller.address
    )
    if(!hasFactoryRole) {
        throw new Error("Caller does not have FACTORY_ROLE on new factory");
    }

    const implementations: string[] = []; // replace
    const data = implementations.map((impl) => twFactory.interface.encodeFunctionData("addImplementation", [impl]));

    const tx = await twFactory.multicall(data);
    console.log("Adding implementations: ", tx.hash);

    await tx.wait();

    console.log("Done.");
}

main()
    .then(() => process.exit(0))
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })