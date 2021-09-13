import { ethers } from "hardhat";
import { chainIds } from "./chainIds";

export async function getTxOptions(chainId: number) {
  for (let network of Object.keys(chainIds)) {
    if (chainIds[network as keyof typeof chainIds] == chainId) {
      return options[network as keyof typeof options];
    }
  }
}

const options = {
  matic: {
    gasPrice: ethers.utils.parseUnits("5", "gwei"),
  },

  mumbai: {
    gasPrice: ethers.utils.parseUnits("5", "gwei"),
  },

  rinkeby: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },
};
