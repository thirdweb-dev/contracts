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
  address: "0x394F760b187Ca06431F10DC24400ae5c8fa645f0",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0x06e17322326f6ed715BEFc35F53e5EEA01836cB8",
  abi: packABI
}

export const marketObj = {
  address: "0x15beB4eEb99AbCB94aF60AFFC2fE4D3C41e77890",
  abi: marketAbi
}

export const rngObj = {
  address: "0x95196b3Cf1Cd1e007bA3b12CF2794A2aB0ef53d6",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0xF3cD296A5a120FC8043E0e24C0e7857C24c29143",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


