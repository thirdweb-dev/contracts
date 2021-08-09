import { ethers } from 'ethers';
import * as dotenv from 'dotenv'
dotenv.config();

export const addresses = {
  matic: {
    controlCenter: "",
    pack: "",
    market: "",
    rewards: ""
  },
  mumbai: {
    controlCenter: "0x28F7BDF6902d09c6EF2496976Fd886e47adce744",
    pack: "0xFe92320f002062e8dE6Af21970Ad8Fc4B024C2Bf",
    market: "0xD73f01f9c143EFc6Fe8eE110aF334D9ff1F2E852",
    rewards: "0xF0D1064ec8Dee772af45D6e9E45Cfa5F429d80a7"
  },
  rinkeby: {
    controlCenter: "",
    pack: "",
    market: "",
    rewards: ""
  },
  mainnet: {
    controlCenter: "",
    pack: "",
    market: "",
    rewards: ""
  }
}

export const provider = (network: string) => new ethers.providers.JsonRpcProvider(
  `https://eth-${network}.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  network
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const wallet = (network: string) => new ethers.Wallet(privateKey, provider(network));


