import hre, { run, ethers } from "hardhat";
import { Contract } from "ethers";

import addresses from "../utils/addresses/accesspacks.json";
import { txOptions } from "../utils/txOptions";

async function main() {
  await run("compile");

  console.log("\n");

  const grantTo: string = "0xa05271523BD00593eb4CC6DCbDcbd045361a9a03";

  // Get signer
  const [deployer] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  // Get chain specific values
  const curentNetworkAddreses = addresses[networkName as keyof typeof addresses];
  const packAddress = "0xB350f6b4FD9e2009ad64db4E7a064E00dB82cE67";
  const accessNftAddress = "0xf1482e0aC5742B0683f51ed8e87bdbFA66f3da3f";
  const txOption = txOptions[networkName as keyof typeof txOptions];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Grant roles
  const pack: Contract = await ethers.getContractAt("Pack", packAddress);
  const accessNft: Contract = await ethers.getContractAt("AccessNFT", accessNftAddress);

  // Get roles
  const MINTER_ROLE = await pack.MINTER_ROLE();
  const DEFAULT_ADMIN_ROLE = await pack.DEFAULT_ADMIN_ROLE();

  // Grant roles tx
  const tx1 = await pack.grantRole(MINTER_ROLE, grantTo, txOption);
  console.log("Granting MINTER_ROLE on pack at: ", tx1.hash);
  await tx1.wait();

  const tx2 = await pack.grantRole(DEFAULT_ADMIN_ROLE, grantTo, txOption);
  console.log("Granting DEFAULT_ADMIN_ROLE on pack at: ", tx2.hash);
  await tx2.wait();

  const tx3 = await accessNft.grantRole(MINTER_ROLE, grantTo, txOption);
  console.log("Granting MINTER_ROLE on accessNft at: ", tx3.hash);
  await tx3.wait();

  const tx4 = await accessNft.grantRole(DEFAULT_ADMIN_ROLE, grantTo, txOption);
  console.log("Granting DEFAULT_ADMIN_ROLE on accessNft at: ", tx4.hash);
  await tx4.wait();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
