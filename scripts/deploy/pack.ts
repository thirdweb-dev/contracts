import hre, { ethers } from "hardhat";
import { Pack } from "typechain";
import { nativeTokenWrapper } from "../../utils/nativeTokenWrapper";

async function main() {
        
        const chainId: number = hre.network.config.chainId as number;
        const nativeTokenWrapperAddress: string = nativeTokenWrapper[chainId];

        const pack: Pack = await ethers.getContractFactory("Pack").then(f => f.deploy(nativeTokenWrapperAddress));
        console.log("Deploying Pack \ntransaction: ", pack.deployTransaction.hash, "\naddress: ", pack.address);
        await pack.deployTransaction.wait();
        console.log("\n");

        console.log("Verifying contract");
        await verify(pack.address, [nativeTokenWrapperAddress]);
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
    console.error(e);
    process.exit(1);
})