import { ethers } from "hardhat";
import { Contract, BigNumber } from "ethers";

import { addresses } from "../../utils/contracts";

// Transaction parameters.
const id: BigNumber = BigNumber.from(0);

async function openPack(packId: BigNumber) {
  // Setting manual gas limit.
  const manualGasPrice: BigNumber = ethers.utils.parseUnits("5", "gwei");

  // Get signer.
  const [caller] = await ethers.getSigners();

  // Get contract instances connected to wallet.
  const {
    mumbai: { pack },
  } = addresses;
  const packContract: Contract = await ethers.getContractAt("Pack", pack);

  // Open pack.
  const openTx = await packContract.connect(caller).openPack(packId, { gasPrice: manualGasPrice });
  console.log("Opening pack: ", openTx.hash);
  await openTx.wait();
}

openPack(id)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
