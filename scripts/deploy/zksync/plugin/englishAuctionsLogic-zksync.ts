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
  const artifact: ZkSyncArtifact = (await hre.artifacts.readArtifact("EnglishAuctionsLogic")) as ZkSyncArtifact;
  const englishAuctions = new ContractFactory(artifact.abi, artifact.bytecode, wallet, "create");

  // WETH address as constructor param
  // Zksync Mainnet: 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91
  // Zksync Sepolia: 0x0462C05457Fed440740Ff3696bDd2D0577411e34
  // abstract testnet: 0x9EDCde0257F2386Ce177C3a7FCdd97787F0D841d
  // lens sepolia testnet: 0xaA91D645D7a6C1aeaa5988e0547267B77d33fe16
  // xsolla testnet: 0xb0b8b267d44c64BA6dD1Daf442949887c85199f6
  // abstract mainnet: 0x3439153EB7AF838Ad19d56E1571FBD09333C2809
  const contract = await englishAuctions.deploy("0x3439153EB7AF838Ad19d56E1571FBD09333C2809");
  await contract.deployed();

  console.log("Deployed EnglishAuctionsLogic \n: ", contract.address);

  console.log("\n");

  console.log("Verifying contract.");
  // deployed address zksync mainnet: 0xcd86890BC05dC3118DAC90330722b23c6cc970e2
  // deployed address zksync sepolia: 0xefE2fF8F3282Fd63898cb0A532099BA7780b459F
  // deployed address abstract testnet: 0x7689AB65593EDdD140c53d697253b533F54CeA1B
  // lens sepolia testnet: 0xe320543648D417858f9666C45C9723AB6355cA84
  // xsolla testnet: 0xF73EFC402e9467ED756598193dD74ac4C1615724
  // abstract mainnet: 0xf3C7d3F0AA374a2D32489929e24D3e9313Aec8bb
  await verify(
    contract.address,
    "contracts/prebuilts/marketplace/english-auctions/EnglishAuctionsLogic.sol:EnglishAuctionsLogic",
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
