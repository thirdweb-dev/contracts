import { ethers } from 'ethers';
import * as dotenv from 'dotenv'
dotenv.config();

import controlCenterAbi from '../abi/ProtocolControl.json';
import packABI from '../abi/Pack.json';
import marketAbi  from '../abi/Market.json';
import rngAbi from '../abi/RNG.json';
import rewardsABI from '../abi/Rewards.json';

dotenv.config();

export const controlCenterObj = {
  address: "0x17537395d4fA74C0fEC130285887DDD44ce2CbD6",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0xd6Df35AD43bD53cDAdC69986434AAf18422F9D7E",
  abi: packABI
}

export const marketObj = {
  address: "0x7B7074095AFeAa7976BC3dBE20421E19195534Bd",
  abi: marketAbi
}

export const rngObj = {
  address: "0x31Fe46A9f5046f329a7c4dD5ad87f1A2543390f6",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0xF0D1064ec8Dee772af45D6e9E45Cfa5F429d80a7",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


