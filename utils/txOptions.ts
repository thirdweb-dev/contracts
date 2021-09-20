import { ethers } from "hardhat";

export const txOptions = {
  polygon: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },

  matic: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },

  mumbai: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },

  rinkeby: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },

  localhost: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },
};
