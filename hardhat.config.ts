import "@nomiclabs/hardhat-waffle";
import "hardhat-abi-exporter";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";

import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

import dotenv from "dotenv";
dotenv.config();

const chainIds = {
  ganache: 1337,
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
  polygon: 137,
  mumbai: 80001,
};

// Ensure that we have all the environment variables we need.
let testPrivateKey: string = process.env.TEST_PRIVATE_KEY || "";
let alchemyKey: string = process.env.ALCHEMY_KEY || "";
let etherscanKey: string = process.env.ETHERSCAN_API_KEY || "";
let polygonscanKey: string = process.env.POLYGONSCAN_API_KEY || "";

function createTestnetConfig(network: keyof typeof chainIds): NetworkUserConfig {
  if (!alchemyKey) {
    throw new Error("Missing ALCHEMY_KEY");
  }

  const polygonNetworkName = network === "polygon" ? "mainnet" : "mumbai";

  let nodeUrl =
    chainIds[network] == 137 || chainIds[network] == 80001
      ? `https://polygon-${polygonNetworkName}.g.alchemy.com/v2/${alchemyKey}`
      : `https://eth-${network}.alchemyapi.io/v2/${alchemyKey}`;

  return {
    chainId: chainIds[network],
    url: nodeUrl,
    accounts: [`${testPrivateKey}`],
  };
}

interface ConfigWithEtherscan extends HardhatUserConfig {
  etherscan: { apiKey: string };
}

const config: ConfigWithEtherscan = {
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.0",
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/solidity-template/issues/31
        bytecodeHash: "none",
      },
      // You should disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 800,
      },
    },
  },
  abiExporter: {
    flat: true,
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  etherscan: {
    // apiKey: etherscanKey,
    apiKey: polygonscanKey,
  },
};

if (testPrivateKey) {
  config.networks = {
    mainnet: createTestnetConfig("mainnet"),
    rinkeby: createTestnetConfig("rinkeby"),
    polygon: createTestnetConfig("polygon"),
    mumbai: createTestnetConfig("mumbai"),
  };
}

export default config;
