import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BytesLike } from "@ethersproject/bytes";

import { TWRegistry } from "typechain";

async function main() {
  const [roleHolder]: SignerWithAddress[] = await ethers.getSigners();

  const twRegistryAddress: string = ethers.constants.AddressZero; // replace
  const twRegistry: TWRegistry = await ethers.getContractAt("TWRegistry", twRegistryAddress);

  const isAdminOnRegistry: boolean = await twRegistry.hasRole(
    await twRegistry.DEFAULT_ADMIN_ROLE(),
    roleHolder.address,
  );
  if (!isAdminOnRegistry) {
    throw new Error("Caller provided is not admin on registry");
  } else {
    console.log("Caller provided is admin on registry. Revoking role now.");
  }

  const role: BytesLike = ""; // replace

  const revokeRoleTx = await twRegistry
    .connect(roleHolder)
    .revokeRole(role, roleHolder.address);

  console.log(`\nRevoking admin role from ${roleHolder.address} at tx: ${revokeRoleTx.hash}`);

  await revokeRoleTx.wait();

  console.log("Done.");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
