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
  address: "0x28F7BDF6902d09c6EF2496976Fd886e47adce744",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0xFe92320f002062e8dE6Af21970Ad8Fc4B024C2Bf",
  abi: packABI
}

export const marketObj = {
  address: "0xD73f01f9c143EFc6Fe8eE110aF334D9ff1F2E852",
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


