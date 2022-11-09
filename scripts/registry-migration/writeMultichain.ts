import fs from "fs";
import { ethers } from "hardhat";
import { TWMultichainRegistry } from "typechain";

async function main() {
  const twMultichainRegistryAddress: string = ""; // replace
  const twMultichainRegistry: TWMultichainRegistry = await ethers.getContractAt(
    "TWMultichainRegistry",
    twMultichainRegistryAddress,
  );

  let migrationData = JSON.parse(fs.readFileSync("./scripts/registry-migration/migration-data.json", "utf-8"));

  console.log("getting all deployments now");
  let txns: any[] = [];
  for (let i = 0; i < 1; i++) {
    const txData = await twMultichainRegistry.populateTransaction.add(
      migrationData[i].deployer,
      migrationData[i].deployment,
      migrationData[i].chainId,
      "",
    );

    txns.push(txData.data);
    const txrec = await twMultichainRegistry.multicall(txns);
    await txrec.wait();
  }
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
