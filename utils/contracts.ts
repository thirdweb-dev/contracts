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
  address: "0x2d1Fb9f24775551a0331ACc6444Dfa10D9bb0eB0",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0x826e5Fe2548a47EFe5ed6D1a11915b7F7511DB04",
  abi: packABI
}

export const marketObj = {
  address: "0xb83c938C06600Cc5a93794df783285FC2d64c259",
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


