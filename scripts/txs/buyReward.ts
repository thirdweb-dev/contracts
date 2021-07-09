import { ethers } from 'hardhat';
import { Signer, Contract, BigNumber } from 'ethers';
import * as dotenv from 'dotenv';

import marketAbi  from '../../abi/Market.json';
import accessPacksABI from '../../abi/AccessPacks.json';

dotenv.config();

const marketObj = {
  address: "0x4e894D3664648385f18D6497bdEaC0574F91B48B",
  abi: marketAbi
}

const accessPacksObj = {
  address: "0xB98C0E788fb82297a73E32296e246653390eCE68",
  abi: accessPacksABI
}

const rewardContract: string = "0xB98C0E788fb82297a73E32296e246653390eCE68";
const from: string = "0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372";
const rewardId: BigNumber = BigNumber.from(2);
const quantityToBuy: BigNumber = BigNumber.from(1);

const salePrice: BigNumber = ethers.utils.parseEther("0.01");

async function buyReward(
  rewardContract: string,
  from: string,
  rewardId: BigNumber,
  quantityToBuy: BigNumber,
  pricePerToken: BigNumber
) {

  const manualGasLimit: number = 1000000; // 1 mil
  const priceToPay: BigNumber = quantityToBuy.mul(pricePerToken);

  const [buyer]: Signer[] = await ethers.getSigners();
  const market: Contract = new ethers.Contract(marketObj.address, marketObj.abi, buyer);

  const buyTx = await market.buyRewards(rewardContract, from, rewardId, quantityToBuy, { gasLimit: manualGasLimit, value: priceToPay });
  console.log("Buying rewards: ", buyTx.hash);
  await buyTx.wait();
}

buyReward(
  rewardContract,
  from,
  rewardId,
  quantityToBuy,
  salePrice
).then(() => process.exit(1))
  .catch(err => {
    console.error(err)
    process.exit(1)
  });