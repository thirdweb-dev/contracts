import { ThirdwebSDK } from "@thirdweb-dev/sdk";

import { DEFAULT_CHAINS, apiMap, chainIdApiKey } from "./constants";

////// To run this script: `npx ts-node scripts/deploy-prebuilt-deterministic/verify.ts` //////
const deployedContractName = "AccountExtension";
const secretKey: string = process.env.THIRDWEB_SECRET_KEY as string;

async function main() {
  console.log("---------- Verification ---------");
  console.log();
  for (const chain of DEFAULT_CHAINS) {
    const sdk = new ThirdwebSDK(chain, {
      secretKey,
    });
    console.log("Network: ", chain.slug);
    try {
      await sdk.verifier.verifyThirdwebContract(
        deployedContractName,
        apiMap[chain.chainId],
        chainIdApiKey[chain.chainId] as string,
      );
      console.log();
    } catch (error) {
      if ((error as Error)?.message?.includes("already verified")) {
        console.log("Already verified");
      } else {
        console.log(error);
      }
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
