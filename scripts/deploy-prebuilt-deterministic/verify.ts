import { ThirdwebSDK } from "@thirdweb-dev/sdk";

import { apiMap, chainIdApiKey, chainIdToName } from "./constants";

////// To run this script: `npx ts-node scripts/deploy-prebuilt-deterministic/verify.ts` //////
const deployedContractName = "VoteERC20";

async function main() {
  console.log("---------- Verification ---------");
  console.log();
  for (const [chainId, networkName] of Object.entries(chainIdToName)) {
    const sdk = new ThirdwebSDK(chainId);
    console.log("Network: ", networkName);
    try {
      await sdk.verifier.verifyThirdwebContract(
        deployedContractName,
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
