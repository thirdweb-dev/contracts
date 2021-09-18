import { ethers } from "hardhat";

export const txOptions = {
  matic: {
    gasPrice: ethers.utils.parseUnits("5", "gwei"),
  },

  mumbai: {
    gasPrice: ethers.utils.parseUnits("5", "gwei"),
  },

  rinkeby: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },

  localhost: {
    gasPrice: ethers.utils.parseUnits("10", "gwei"),
  },
};
