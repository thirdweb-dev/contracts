import { ethers } from 'hardhat';
import { Signer, Contract } from 'ethers';
import * as dotenv from 'dotenv';

dotenv.config();

import accessPacksABI from '../../abi/AccessPacks.json';

const accessPacksObj = {
  address: "0xB98C0E788fb82297a73E32296e246653390eCE68",
  abi: accessPacksABI
}

async function main() {
  const [deployer]: Signer[] = await ethers.getSigners();

  const accessPacks: Contract = new ethers.Contract(accessPacksObj.address, accessPacksObj.abi, deployer);

  const rewardURIs: string[] = [
    "ipfs://QmUEfhF9FpucMVfjySnDmFvq3nKwGNtNk83qDwMEt3JDCL",
    "ipfs://QmXmp3FWWELBwb7wxRD98ps96iYRUXUycPvd1LQ23WhRhW",
    "QmUxgEgxvFeiJHAMLK9oWpS6yZmR8EzyJpzQmCc2Gv99U6"
  ]

  const rewardSupplies = [5, 10, 20];

  const createRewardsTx = await accessPacks.createNativeRewards(rewardURIs, rewardSupplies);
  console.log("Creating rewards: ", createRewardsTx.hash);

  await createRewardsTx.wait();
}

main()
    .then(() => process.exit(0))
    .catch(err => {
      console.error(err)
      process.exit(1)
    })