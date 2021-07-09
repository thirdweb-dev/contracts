import { ethers } from 'hardhat';
import { Signer, Contract, BigNumber } from 'ethers';
import * as dotenv from 'dotenv';

import marketAbi  from '../../abi/Market.json';

dotenv.config();

const marketObj = {
  address: "0x4e894D3664648385f18D6497bdEaC0574F91B48B",
  abi: marketAbi
}

const from: string = "0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372";
const packId: BigNumber = BigNumber.from(0);
const quantityToBuy: BigNumber = BigNumber.from(1);

const salePrice: BigNumber = ethers.utils.parseEther("0.01");

async function buyPack(from: string, packId: BigNumber, quantityToBuy: BigNumber, pricePerToken: BigNumber) {

  const manualGasLimit: number = 1000000; // 1 mil
  
  const [buyer]: Signer[] = await ethers.getSigners();
  const market: Contract = new ethers.Contract(marketObj.address, marketObj.abi, buyer);

  const priceToPay: BigNumber = quantityToBuy.mul(pricePerToken);

  const buyTx = await market.buyPacks(from, packId, quantityToBuy, { gasLimit: manualGasLimit, value: priceToPay });
  console.log("Buying one pack from market listing: ", buyTx.hash);
  await buyTx.wait();
}

buyPack(from, packId, quantityToBuy, salePrice)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  });