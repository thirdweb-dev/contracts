import { ethers } from "ethers";
import { ThirdwebSDK } from "@thirdweb-dev/sdk";
import { readFileSync } from "fs";

import dotenv from "dotenv";
dotenv.config();


////// To run this script: `npx ts-node scripts/plugin_setup/setExtensionFromABI.ts` //////
///// Please cmd F 'PASTE' to check wherever you need to paste relevant information in the script. //////

async function main() {

  /*///////////////////////////////////////////////////////////////
                    Get ABI to register in MAP
  //////////////////////////////////////////////////////////////*/

  const extensionFileName = ""; // PASTE
  const contractName = ""; // PASTE
  const ABI = JSON.parse(readFileSync(`artifacts_forge/${extensionFileName}.sol/${contractName}.json`, "utf-8")).abi

  const unwantedList: string[] = []; // PASTE

  console.log("\nRegistering the following functions to MAP:")
  for(const x of ABI) {
    if(x.type == "function" && !unwantedList.includes(x.name)) {
        console.log(x.name);
    }
  }
  console.log("\n");

  /*///////////////////////////////////////////////////////////////
                    Connect to MAP contract
  //////////////////////////////////////////////////////////////*/

  const sdk = ThirdwebSDK.fromPrivateKey(process.env.THIRDWEB_WALLET_TEST_PKEY as string, "goerli");

  const MAP: string = ""; // PASTE the address of the relevant MAP contract.
  const map = await sdk.getContract(
    MAP,
    JSON.parse(readFileSync("artifacts_forge/Map.sol/Map.json", "utf-8")).abi,
  );

  const iface = new ethers.utils.Interface(ABI);
  const extensionAddress = ""; // PASTE the extension address to map the registered functions to.
  const multicallData = [];

  for(const x of ABI) {
    if(x.type == "function" && !unwantedList.includes(x.name)) {
        const sig = iface.getSighash(x.name);
        console.log(sig);
        const txData = map.encoder.encode("setExtension", [sig, extensionAddress])
        multicallData.push(txData);
    }
  }

  console.log("Registering functions with extension: ", extensionAddress);
  const tx = await map.call("multicall", multicallData);
  console.log(tx);

}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });