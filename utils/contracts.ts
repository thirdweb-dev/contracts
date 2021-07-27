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
  address: "0xA0dd9C617a941de9B044C43f330aA0B9F2111CAf",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0x69b014f52059127f0119e9e1Ab5E3c60f4A5FF58",
  abi: packABI
}

export const marketObj = {
  address: "0x49ae606B0AC72D744C6A84C3Cf0e8c29aB8a3db5",
  abi: marketAbi
}

export const rngObj = {
  address: "0xF53dFc5B65c5C8712235A1ee81e18fb021ebCC0f",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0x32E94dfd93D9a409572561B1D54cda229d61B051",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


