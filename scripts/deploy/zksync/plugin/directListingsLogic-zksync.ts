import { Wallet, Provider, ContractFactory } from "zksync-ethers";
import * as hre from "hardhat";
import dotenv from "dotenv";
import { ZkSyncArtifact } from "@matterlabs/hardhat-zksync-solc/dist/src/types";

import "@matterlabs/hardhat-zksync-node/dist/type-extensions";
import "@matterlabs/hardhat-zksync-verify/dist/src/type-extensions";

dotenv.config();

async function main() {
  const provider = new Provider(hre.network.config.url);
  const wallet = new Wallet(`${process.env.TEST_PRIVATE_KEY}`, provider);
  const artifact: ZkSyncArtifact = (await hre.artifacts.readArtifact("DirectListingsLogic")) as ZkSyncArtifact;
  const directListings = new ContractFactory(artifact.abi, artifact.bytecode, wallet, "create");

  // WETH address as constructor param
  // Zksync Mainnet: 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91
  // Zksync Sepolia: 0x0462C05457Fed440740Ff3696bDd2D0577411e34
  // abstract testnet: 0x9EDCde0257F2386Ce177C3a7FCdd97787F0D841d
  // lens sepolia testnet: 0xaA91D645D7a6C1aeaa5988e0547267B77d33fe16
  // xsolla testnet: 0xb0b8b267d44c64BA6dD1Daf442949887c85199f6
  // abstract mainnet: 0x3439153EB7AF838Ad19d56E1571FBD09333C2809
  const contract = await directListings.deploy("0x3439153EB7AF838Ad19d56E1571FBD09333C2809");
  await contract.deployed();

  console.log("Deployed DirectListingsLogic \n: ", contract.address);

  console.log("\n");

  console.log("Verifying contract.");
  // deployed address zksync mainnet: 0xfaCf7A60a24E28534c643653c974540343f5ff09
  // deployed address zksync sepolia: 0x8b0DBCf5b7D01eBB0F24525CE8AB72F16CE4F8C8
  // deployed address abstract testnet: 0xab2b0451C07f35FB490A3939BD4DfE327013d2A6
  // lens sepolia testnet: 0xF73EFC402e9467ED756598193dD74ac4C1615724
  // xsolla testnet: 0x038890935747f67B45c83fe99a15B0A94AEb996c
  // abstract mainnet: 0x26279882D5E93045D4FA986847CAAC048b2Bac3b
  await verify(
    contract.address,
    "contracts/prebuilts/marketplace/direct-listings/DirectListingsLogic.sol:DirectListingsLogic",
    ["0x3439153EB7AF838Ad19d56E1571FBD09333C2809"],
  );
}

async function verify(address: string, contract: string, args: any[]) {
  try {
    return await hre.run("verify:verify", {
      address: address,
      contract: contract,
      constructorArguments: args,
    });
  } catch (e) {
    console.log(address, args, e);
  }
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
