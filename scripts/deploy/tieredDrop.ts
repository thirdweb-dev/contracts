import hre, { ethers } from "hardhat";
import type {
  BytesLike
} from "ethers";
import { TieredDropLogic, TieredDrop } from "typechain";

// eslint-disable-next-line @typescript-eslint/no-namespace
namespace IPlugin {
  export type PluginFunctionStruct = {
    functionSelector: BytesLike; //0xabcdef
    functionSignature: string; // "transfer(address,address,uint256)"
  };

  export type PluginMetadataStruct = {
    name: string;
    metadataURI: string;
    implementation: string;
  };

  export type PluginStruct = {
    metadata: PluginMetadataStruct;
    functions: PluginFunctionStruct[];
  };
}

async function main() {

  const tieredDropLogic: TieredDropLogic = await ethers.getContractFactory("TieredDropLogic").then(f => f.deploy());

  console.log(
    "Deploying TieredDropLogic \ntransaction: ",
    tieredDropLogic.deployTransaction.hash,
    "\naddress: ",
    tieredDropLogic.address,
  );

  await tieredDropLogic.deployTransaction.wait();

  console.log("\n");

  console.log("Verifying contract.");
  await verify(tieredDropLogic.address, []);

  const metadata: IPlugin.PluginMetadataStruct = {
    name: "TieredDropLogic",
    metadataURI: "",
    implementation: tieredDropLogic.address
  }

  // TODO: use ABI to generate this
  // example: let iface = new ethers.utils.Interface(ABI);
  const functions: IPlugin.PluginFunctionStruct[] = [

  ]

  const plugin: IPlugin.PluginStruct = { metadata, functions };

  const tieredDrop: TieredDrop = await ethers.getContractFactory("TieredDrop").then(f => f.deploy([plugin]));

  console.log(
    "Deploying TieredDrop \ntransaction: ",
    tieredDrop.deployTransaction.hash,
    "\naddress: ",
    tieredDrop.address,
  );

  await tieredDrop.deployTransaction.wait();

  console.log("\n");

  console.log("Verifying contract.");
  await verify(tieredDrop.address, []);
}

async function verify(address: string, args: any[]) {
  try {
    return await hre.run("verify:verify", {
      address: address,
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
