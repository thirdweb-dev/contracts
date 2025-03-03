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
  const artifact: ZkSyncArtifact = (await hre.artifacts.readArtifact("OffersLogic")) as ZkSyncArtifact;
  const offers = new ContractFactory(artifact.abi, artifact.bytecode, wallet, "create");

  const contract = await offers.deploy();
  await contract.deployed();

  console.log("Deployed OffersLogic \n: ", contract.address);

  console.log("\n");

  console.log("Verifying contract.");
  // deployed address zksync mainnet: 0x5f4964a30b86B626BCAAaCc4622CB70d76c844f2
  // deployed address zksync sepolia: 0xB89DbEe6fA8664507b0f7758bCc532817CAf6Eb2
  // deployed address abstract testnet: 0x98B25911d02851b0a39D5947ac6012efC92E6c79
  // deployed address lens testnet: 0x038890935747f67B45c83fe99a15B0A94AEb996c
  // deployed address xsolla testnet: 0x4c7416f13deB20215Ab1A163B63b35E03Fa3Fae1
  // abstract mainnet: 0x56Abb6a3f25DCcdaDa106191053b1CC54C196DEE
  await verify(contract.address, "contracts/prebuilts/marketplace/offers/OffersLogic.sol:OffersLogic", []);
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
