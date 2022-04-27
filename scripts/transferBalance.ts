import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

async function main() {
    
    const receiver: string = ethers.constants.AddressZero; // replace

    const [caller]: SignerWithAddress[] = await ethers.getSigners();

    console.log(`\nTransferring balance from ${caller.address} to ${receiver}`);

    const balance = await ethers.provider.getBalance(caller.address);
    const gasPrice = ethers.utils.parseUnits("0", "gwei"); // replace
    const cost = gasPrice.mul(21_000);

    const tx = await caller.sendTransaction({
        to: receiver,
        gasPrice: gasPrice,
        value: balance.sub(cost)
    });
    console.log("Transferring balance: ", tx.hash);
    await tx.wait();

    console.log("Done.");
}

main()
    .then(() => process.exit(0))
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })