// from: https://github.com/ethereumvex/SushiMaker-bridge-exploit/blob/master/utils/utils.js
import hre from "hardhat";
const ethers = hre.ethers;
require('dotenv').config();

export const forkFrom = async (blockNumber: any) => {  
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // jsonRpcUrl: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
            jsonRpcUrl: `https://rpc-mumbai.matic.today`,
            blockNumber: blockNumber,
          },
        },
      ],
    });
};

export const impersonate = async function getImpersonatedSigner(address: any) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [address]
    });
    return ethers.provider.getSigner(address);
}