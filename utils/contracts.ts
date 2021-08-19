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
    controlCenter: "0x3d86dD9846c0a15B0f40037AAf51CC68A4236add",
    pack: "0xD89eE4F34BC76315E77D808305c0931f28Fa3C5D",
    market: "0xD521909301724a02E0C66599Dfb5A47d4390fc43",
    rewards: "0x7c6c7048Cd447BA200bde9A89A2ECc83435b7E51"
  },
  rinkeby: {
    controlCenter: "0xAFe8f8EDad3Fd7b0108997b51CCd24286FbF000B",
    pack: "0x928C9EE38048e5D0A4601D1FDcF7B9E57317278D",
    market: "0x92902EF66B71a4646d3B33FD16ffC7EaD0182faC",
    rewards: "0xebC0b11f62A416634fe400bbB750f0E40833a4d0"
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


