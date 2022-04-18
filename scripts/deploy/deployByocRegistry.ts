import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { TWRegistry } from "typechain/TWRegistry";
import { ByocRegistry } from "typechain/ByocRegistry";

async function main() {

    const [deployer]: SignerWithAddress[] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);

    const trustedForwarders: string[] = ["0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81"];

    const registry: TWRegistry = await ethers.getContractFactory("TWRegistry").then(f => f.deploy(trustedForwarders[0]));
    console.log("TWRegistry deployed at: ", registry.address)

    const byocRegsitry: ByocRegistry = await ethers.getContractFactory("ByocRegistry").then(f => f.deploy(
        registry.address,
        trustedForwarders
    ));

    console.log("Deployed ByocRegistry at: ", byocRegsitry.address);

    const tx = await registry.grantRole(
        await registry.OPERATOR_ROLE(),
        byocRegsitry.address
    );
    console.log("Granting operator role to ByocRegistry: ", tx.hash);

    await tx.wait();

    console.log("Done");
}

main()
    .then(() => process.exit(0))
    .catch((e) => {
        console.error(e);
        process.exit(1)
    })