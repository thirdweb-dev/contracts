import hre, { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Multiwrap } from "typechain";
import { nativeTokenWrapper } from "../../utils/nativeTokenWrapper";

async function main() {

    const [caller]: SignerWithAddress[] = await ethers.getSigners();
    
    const chainId: number = hre.network.config.chainId as number;
    const nativeTokenWrapperAddress: string = nativeTokenWrapper[chainId];
    
    const multiwrap: Multiwrap = await ethers.getContractFactory("Multiwrap").then(f => f.deploy(nativeTokenWrapperAddress));
    console.log("Deploying Multiwrap \ntransaction: ", multiwrap.deployTransaction.hash, "\naddress: ", multiwrap.address);
    await multiwrap.deployTransaction.wait();

    console.log("\n")

    console.log("Verifying contract.")
    await verify(multiwrap.address, [nativeTokenWrapperAddress]);
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