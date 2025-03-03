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
  const artifact: ZkSyncArtifact = (await hre.artifacts.readArtifact("MarketplaceV3")) as ZkSyncArtifact;
  const marketplaceV3 = new ContractFactory(artifact.abi, artifact.bytecode, wallet, "create");

  // WETH address as constructor param
  // Zksync Mainnet: 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91
  // Zksync Sepolia: 0x0462C05457Fed440740Ff3696bDd2D0577411e34
  // abstract testnet: 0x9EDCde0257F2386Ce177C3a7FCdd97787F0D841d
  // lens sepolia testnet: 0xaA91D645D7a6C1aeaa5988e0547267B77d33fe16
  // xsolla testnet: 0xb0b8b267d44c64BA6dD1Daf442949887c85199f6
  // abstract mainnet: 0x3439153EB7AF838Ad19d56E1571FBD09333C2809
  const contract = await marketplaceV3.deploy(
    "0x9742f5ac11958cFAd151eBF0Fc31302fA409036E", // pluginMap address
    "0x0000000000000000000000000000000000000000", // royalty engine address - set to address(0)
    "0x3439153EB7AF838Ad19d56E1571FBD09333C2809", // WETH address
  );
  await contract.deployed();

  console.log("Deployed MarketplaceV3 \n: ", contract.address);

  console.log("\n");

  console.log("Verifying contract.");

  // deployed address zksync mainnet: 0xBc02441a36Bb4029Cd191b20243c2e41B862F118
  // deployed address zksync sepolia: 0x58e0F289C7dD2025eBd0696d913ECC0fdc1CC8bc
  // deployed address abstract testnet: 0x2dA4Dd326A6482679547071be21f74685d730504
  // lens sepolia testnet: 0x56Abb6a3f25DCcdaDa106191053b1CC54C196DEE
  // xsolla testnet: 0x9EB0830B0b10010F2a53383517A7D0B75531Bb1b
  // abstract mainnet: 0x4027561E163a420c4e5Db46E07EBd581CAa8Bb62
  await verify(contract.address, "contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol:MarketplaceV3", [
    "0x9742f5ac11958cFAd151eBF0Fc31302fA409036E",
    "0x0000000000000000000000000000000000000000",
    "0x3439153EB7AF838Ad19d56E1571FBD09333C2809",
  ]);
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
