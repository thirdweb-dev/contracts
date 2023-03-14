import "dotenv/config";
import { SUPPORTED_CHAIN_ID, ThirdwebSDK } from "@thirdweb-dev/sdk";
import { readFileSync } from "fs";
import { chainIdToName } from "./constants";

////// To run this script: `npx ts-node scripts/release/check.ts` //////
///// MAKE SURE TO PUT IN THE RIGHT CONTRACT NAME HERE AFTER CREATING A RELEASE FOR IT /////
//// THE RELEASE SHOULD HAVE THE IMPLEMENTATIONS ALREADY DEPLOYED AND RECORDED (via dashboard) ////
const privateKey: string = process.env.DEPLOYER_KEY as string; // should be the correct deployer key

const polygonSDK = ThirdwebSDK.fromPrivateKey(privateKey, "polygon");

async function main() {
  const contractOne = await polygonSDK.getContract("0x1e41eb9e6bd324447c666e039fe9417d219b2fc0", "marketplace-v3");
  const contractTwo = await polygonSDK.getContract("0xeca12604868a122958def98eaad623cd2b4a1d32", "marketplace");

  const one = await contractTwo.getAllListings({
    tokenId: 1,
  });

  console.log(one);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
