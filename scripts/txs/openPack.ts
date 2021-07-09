import { ethers } from 'hardhat';
import { Signer, Contract, BigNumber } from 'ethers';
import * as dotenv from 'dotenv';

import handlerABI from '../../abi/Handler.json';
import packABI from '../../abi/Pack.json';

dotenv.config();

const handlerObj = {
  address: "0xE0c4F0058f339Ac5881ad1FDcfdF3a16190E94Eb",
  abi: handlerABI
}

const packObj = {
  address: "0x982Fe0d70Da1BEaa396778830ACcF19062c83a6E",
  abi: packABI
}

const packId: BigNumber = BigNumber.from(0);

async function openPack(packId: BigNumber) {

  const manualGasLimit: number = 1000000; // 1 mil

  const [packOwner]: Signer[] = await ethers.getSigners();

  const pack: Contract = new ethers.Contract(packObj.address, packObj.abi, packOwner);
  const handler: Contract = new ethers.Contract(handlerObj.address, handlerObj.abi, packOwner);

  const approveHandlerTx = await pack.setApprovalForAll(handler.address, true);
  console.log("Approving Handler to burn pack tokens: ", approveHandlerTx.hash);
  await approveHandlerTx.wait()

  const openTx = await handler.openPack(packId, { gasLimit: manualGasLimit });
  console.log("Opening pack: ", openTx.hash);
  await openTx.wait();
}

openPack(packId)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  })
