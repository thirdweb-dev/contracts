import { ethers } from 'ethers';
import * as dotenv from 'dotenv'
dotenv.config();

import packABI from '../abi/Pack.json';
import handlerABI from '../abi/Handler.json';
import marketAbi  from '../abi/Market.json';
import accessPacksABI from '../abi/AccessPacks.json';

dotenv.config();

export const packObj = {
  address: "0x982Fe0d70Da1BEaa396778830ACcF19062c83a6E",
  abi: packABI
}

export const handlerObj = {
  address: "0xE0c4F0058f339Ac5881ad1FDcfdF3a16190E94Eb",
  abi: handlerABI
}

export const marketObj = {
  address: "0x4e894D3664648385f18D6497bdEaC0574F91B48B",
  abi: marketAbi
}

export const accessPacksObj = {
  address: "0xB98C0E788fb82297a73E32296e246653390eCE68",
  abi: accessPacksABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


