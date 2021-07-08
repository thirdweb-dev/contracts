import { ethers } from 'hardhat';
import { Signer, Contract, BigNumber } from 'ethers';
import * as dotenv from 'dotenv';

import packABI from '../../abi/Pack.json';
import handlerABI from '../../abi/Handler.json';
import marketAbi  from '../../abi/Market.json';
import accessPacksABI from '../../abi/AccessPacks.json';

dotenv.config();

const packObj = {
  address: "0x982Fe0d70Da1BEaa396778830ACcF19062c83a6E",
  abi: packABI
}

const handlerObj = {
  address: "0xE0c4F0058f339Ac5881ad1FDcfdF3a16190E94Eb",
  abi: handlerABI
}

const marketObj = {
  address: "0x4e894D3664648385f18D6497bdEaC0574F91B48B",
  abi: marketAbi
}

const accessPacksObj = {
  address: "0xB98C0E788fb82297a73E32296e246653390eCE68",
  abi: accessPacksABI
}

const rewardContract = accessPacksObj.address;
const packURI = "ipfs://QmbJx772DtMCNpgwDaggZEwBS3C8eCucahgfvUVCzWrHUp";
const rewardIds: number[] = [0,1,2];
const rewardSupplies: number[] = [5,10,15];
const saleCurrency: string = "0x0000000000000000000000000000000000000000";
const salePrice: BigNumber = ethers.utils.parseEther("0.01");

async function createAndListPacks(
  rewardContract: string,
  packURI: string,
  rewardIds: number[],
  rewardSupplies: number[],

  saleCurrency: string,
  salePrice: BigNumber
) {

  const [rewardOwner]: Signer[] = await ethers.getSigners();

  const pack: Contract = new ethers.Contract(packObj.address, packObj.abi, rewardOwner);
  const handler: Contract = new ethers.Contract(handlerObj.address, handlerObj.abi, rewardOwner);
  const market: Contract = new ethers.Contract(marketObj.address, marketObj.abi, rewardOwner);
  const accessPacks: Contract = new ethers.Contract(accessPacksObj.address, accessPacksObj.abi, rewardOwner);

  const approveHandlerTx = await accessPacks.setApprovalForAll(handler.address, true);
  console.log("Approving Handler for reward tokens: ", approveHandlerTx.hash);
  await approveHandlerTx.wait()

  const approveMarketTx = await pack.setApprovalForAll(market.address, true);
  console.log("Approving Market for pack tokens: ", approveMarketTx.hash);
  await approveMarketTx.wait()

  const createPackAndListTx = await handler.createPackAndList(
    rewardContract,
    packURI,
    rewardIds,
    rewardSupplies,
    saleCurrency,
    salePrice
  );
  console.log("Create and list packs for sale: ", createPackAndListTx.hash);
  await createPackAndListTx.wait();

  console.log("SUCCESS");
}

createAndListPacks(
  rewardContract,
  packURI,
  rewardIds,
  rewardSupplies,
  saleCurrency,
  salePrice
).then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })