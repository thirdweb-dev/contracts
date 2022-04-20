import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

async function printNonce() {
    const [deployer]: SignerWithAddress[] = await ethers.getSigners();

    console.log("\nNonce of deployer:\nAddress: ", deployer.address, "\nNonce: ", await deployer.getTransactionCount("latest"));
}

async function bumpNonce(factor: number) {

    const [deployer]: SignerWithAddress[] = await ethers.getSigners();

    console.log("\nCurrent nonce of deployer:\nAddress: ", deployer.address, "\nNonce: ", await deployer.getTransactionCount("latest"));
    
    for(let i = 0; i < factor; i += 1) {

        const tx = await deployer.sendTransaction({
            to: deployer.address,
            value: 1
        });

        console.log("\nBumping nonce at tx: ", tx.hash);

        await tx.wait()

        console.log("New nonce: ", await deployer.getTransactionCount("latest"));
    }

    console.log("Done. Nonce of deployer: ", await deployer.getTransactionCount("latest"));
}

// printNonce()
//     .then(() => process.exit(0))
//     .catch((e) => {
//         console.error(e)
//         process.exit(1)
//     })

// bumpNonce(1)
//     .then(() => process.exit(0))
//     .catch((e) => {
//         console.error(e)
//         process.exit(1)
//     })