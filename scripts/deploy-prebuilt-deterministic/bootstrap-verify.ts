import { ThirdwebSDK } from "@thirdweb-dev/sdk";

import { apiMap, chainIdApiKey, contractsToDeploy } from "./constants";

////// To run this script: `npx ts-node scripts/deploy-prebuilt-deterministic/bootstrap-verify.ts` //////
const chainId = "8453"; // update here

async function main() {
  console.log("---------- Verification ---------");
  console.log();

  const sdk = new ThirdwebSDK(chainId);
  for (const publishedContractName of contractsToDeploy) {
    try {
      await sdk.verifier.verifyThirdwebContract(
        publishedContractName,
        apiMap[parseInt(chainId)],
        chainIdApiKey[parseInt(chainId)] as string,
      );
      console.log();
    } catch (error) {
      console.log(error);
      console.log();
    }
  }

  console.log("All done.");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
