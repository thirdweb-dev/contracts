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
const rewardId: BigNumber = BigNumber.from(2);
const saleCurrency: string = "0x0000000000000000000000000000000000000000";
const salePrice: BigNumber = ethers.utils.parseEther("0.01");
const quantityToSell: BigNumber = BigNumber.from(6);

async function listRewards(
  rewardContract: string,
  tokenId: BigNumber,
  currency: string,
  pricePerToken: BigNumber,
  quantityToSell: BigNumber
) {

  const [rewardOwner]: Signer[] = await ethers.getSigners();
  
  const manualGasLimit: number = 1000000; // 1 mil

  const market: Contract = new ethers.Contract(marketObj.address, marketObj.abi, rewardOwner);
  const accessPacks: Contract = new ethers.Contract(accessPacksObj.address, accessPacksObj.abi, rewardOwner);

  const approveMarketTx = await accessPacks.setApprovalForAll(market.address, true);
  console.log("Approving Market for pack tokens: ", approveMarketTx.hash);
  await approveMarketTx.wait()

  const listRewardsTx = await market.listRewards(rewardContract, tokenId, currency, pricePerToken, quantityToSell, {
    gasLimit: manualGasLimit
  });
  console.log("Listing rewards for sale: ", listRewardsTx.hash)
  await listRewardsTx.wait();
}

listRewards(
  rewardContract,
  rewardId,
  saleCurrency,
  salePrice,
  quantityToSell
).then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  });