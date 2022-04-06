import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { ByocRegistry } from "typechain/ByocRegistry";

async function main() {

    const [deployer]: SignerWithAddress[] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);

    const registryAddress: string = "0x7c487845f98938Bb955B1D5AD069d9a30e4131fd";
    const trustedForwarders: string[] = ["0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81"];

    const byocRegsitry: ByocRegistry = await ethers.getContractFactory("ByocRegistry").then(f => f.deploy(
        registryAddress,
        trustedForwarders
    ));

    console.log("Deployed ByocRegistry at: ", byocRegsitry.address);
}

main()
    .then(() => process.exit(0))
    .catch((e) => {
        console.error(e);
        process.exit(1)
    })