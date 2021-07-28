import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-abi-exporter";
import "@nomiclabs/hardhat-etherscan";
import "solidity-coverage";

import "./tasks/accounts";
import "./tasks/clean";

import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  matic: 137,
  mumbai: 80001,
};

// Ensure that we have all the environment variables we need.
let testPrivateKey: string = process.env.TEST_PRIVATE_KEY || "";
let alchemyKey: string = process.env.ALCHEMY_KEY || "";
let etherscanKey: string = process.env.ETHERSCAN_API_KEY || "";

function createTestnetConfig(network: keyof typeof chainIds): NetworkUserConfig {
  if (!alchemyKey) {
    throw new Error("Missing ALCHEMY_KEY");
  }
  let nodeUrl = `https://polygon-${network}.g.alchemy.com/v2/${alchemyKey}`;

  return {
    chainId: chainIds[network],
    url: nodeUrl,
    accounts: [`${testPrivateKey}`],
  };
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
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
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  abiExporter: {
    flat: true,
  },
  etherscan: {
    apiKey: etherscanKey,
  },
};

if (testPrivateKey) {
  config.networks = {
    matic: createTestnetConfig("matic"),
    mumbai: createTestnetConfig("mumbai"),
  };
}

export default config;
