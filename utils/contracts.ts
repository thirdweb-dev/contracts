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
    controlCenter: "0x932a80d12133daDa78d1eFeAa69C53f35b7717eB",
    pack: "0xdF6D4D22918048bA57e849dBBc83d9Bb502bb150",
    market: "0xc8035e0347A9182E6d9973e8B081b166Bb8F075a",
    rewards: "0xe9559e34a8A32FA8Dc050fAaFD9343B666BC92CF"
  },
  rinkeby: {
    controlCenter: "0x916a0c502Ea07B50e48c5c5D6e6C5e26E6F04e02",
    pack: "0xcD6c2E7439C712464B8D49DD6369C976894EbAdb",
    market: "0xA4377C877dABc47bcCA5D68A182907fC833ef7f4",
    rewards: "0x906f3c4643F0C721eB48A40d3903043B43C43434"
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


