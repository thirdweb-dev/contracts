import { ethers } from "ethers";
import { ThirdwebSDK } from "@thirdweb-dev/sdk";
import { readFileSync } from "fs";

import dotenv from "dotenv";
dotenv.config();

const CreateAccountParams = [
  { name: "signer", type: "address" },
  { name: "accountId", type: "bytes32" },
  { name: "deploymentSalt", type: "bytes32" },
  { name: "initialAccountBalance", type: "uint256" },
  { name: "validityStartTimestamp", type: "uint128" },
  { name: "validityEndTimestamp", type: "uint128" },
];

const TransactionParams = [
  { name: "signer", type: "address" },
  { name: "target", type: "address" },
  { name: "data", type: "bytes" },
  { name: "nonce", type: "uint256" },
  { name: "value", type: "uint256" },
  { name: "gas", type: "uint256" },
  { name: "validityStartTimestamp", type: "uint128" },
  { name: "validityEndTimestamp", type: "uint128" },
];

////// To run this script: `npx ts-node scripts/thirdweb_wallet/test.ts` //////

async function main() {
  /*///////////////////////////////////////////////////////////////
                    Connect to AccountAdmin
  //////////////////////////////////////////////////////////////*/

  const ACCOUNT_ADMIN: string = "0xaedDA1a968aC9d26BbE5Ce5be65a5E77a0aA0339"; // Get value from `scripts/thirdweb_wallet/setup.ts`

<<<<<<< HEAD
  const sdk = ThirdwebSDK.fromPrivateKey(
    process.env.THIRDWEB_WALLET_TEST_PKEY as string,
    "goerli",
    {
      gasless: {
        openzeppelin: {
          relayerUrl: "https://api.defender.openzeppelin.com/autotasks/23a23d0f-886a-4858-a14d-ab08ed487c4a/runs/webhook/74b0e036-fd2e-418b-97d7-69ac094edf7b/8RTrzhrMW56WEcNYXd54Bg",
          relayerForwarderAddress: "0x5001A14CA6163143316a7C614e30e6041033Ac20"
        }
      }
    }
  );
  const accountAdmin = await sdk.getContract(
    ACCOUNT_ADMIN,
    JSON.parse(readFileSync("artifacts_forge/AccountAdmin.sol/AccountAdmin.json", "utf-8")).abi
  );
=======
  const sdk = ThirdwebSDK.fromPrivateKey(process.env.THIRDWEB_WALLET_TEST_PKEY as string, "goerli", {
    gasless: {
      openzeppelin: {
        relayerUrl:
          "https://api.defender.openzeppelin.com/autotasks/23a23d0f-886a-4858-a14d-ab08ed487c4a/runs/webhook/74b0e036-fd2e-418b-97d7-69ac094edf7b/8RTrzhrMW56WEcNYXd54Bg",
        relayerForwarderAddress: "0x5001A14CA6163143316a7C614e30e6041033Ac20",
      },
    },
  });
  const entrypoint = await sdk.getContract(WALLET_ADMIN);
>>>>>>> bee319365492a3d989b495b8e424fad82c5136ad

  /*///////////////////////////////////////////////////////////////
            Create an account / get an account for signer
    //////////////////////////////////////////////////////////////*/

  const username = "test_user";
  const password = "super_secret";

  const createParams = {
    signer: await sdk.wallet.getAddress(),
    accountId: ethers.utils.solidityKeccak256(["string", "string"], [username, password]),
    deploymentSalt: ethers.utils.formatBytes32String("randomSaltSalt"),
    initialAccountBalance: 0,
    validityStartTimestamp: 0,
    validityEndTimestamp: Math.floor(Date.now() / 1000) + 10_000,
  };

<<<<<<< HEAD
  const wrapper = (accountAdmin as any).contractWrapper;
  const chainId = (await sdk.getProvider().getNetwork()).chainId;

  const signatureForCreateAccount = await wrapper.signTypedData(
    sdk.getSigner(),
=======
  const chainId = (await sdk.getProvider().getNetwork()).chainId;

  const signaturForCreateAccount = await sdk.wallet.signTypedData(
>>>>>>> bee319365492a3d989b495b8e424fad82c5136ad
    {
      name: "thirdweb_wallet_admin",
      version: "1",
      chainId,
      verifyingContract: ACCOUNT_ADMIN,
    },
    { CreateAccountParams: CreateAccountParams },
    createParams,
  );

  console.log("\nSignature generated for account creation: ", signatureForCreateAccount);

  // UNCOMMENT TO CREATE NEW ACCOUNT
  // await accountAdmin.call("createAccount", createParams, signatureForCreateAccount);

  const accountAddress: string = await accountAdmin.call("getAccount", createParams.signer, createParams.accountId);
  console.log("Your account is: ", accountAddress); // 0xFE6bE0586560A48d2AF255B6149820382A947899

  /*///////////////////////////////////////////////////////////////
                Perforfming a smart contract interaction
  //////////////////////////////////////////////////////////////*/

  const TOKEN_ADDRESS = "0xD5B9182069AAA1572A1EDCA9aFB00326E634651B";
  const tokenContract = await sdk.getContract(TOKEN_ADDRESS);

  const accountContract = await sdk.getContract(
    accountAddress,
    JSON.parse(readFileSync("artifacts_forge/Account.sol/Account.json", "utf-8")).abi,
  );
  const nonce = await accountContract.call("nonce");

  console.log("Account nonce: ", nonce);

  const accountTransactionParams = {
    signer: createParams.signer,
    target: TOKEN_ADDRESS,
    data: tokenContract.encoder.encode("mintTo", [accountAddress, ethers.utils.parseEther("1")]),
    nonce: nonce,
    value: 0,
    gas: 0,
    validityStartTimestamp: 0,
    validityEndTimestamp: Math.floor(Date.now() / 1000) + 10_000,
  };

  console.log("Account transaction params: ", accountTransactionParams);

  const signaturForTransactionParams = await sdk.wallet.signTypedData(
    {
      name: "thirdweb_wallet",
      version: "1",
      chainId,
      verifyingContract: accountAddress,
    },
    { TransactionParams: TransactionParams },
    accountTransactionParams,
  );

  console.log("Signature for Wallet calling mintTo: ", signaturForTransactionParams);

  const accountTransactionData = accountContract.encoder.encode("execute", [
    accountTransactionParams,
    signaturForTransactionParams,
  ]);

  // NOTE: since the caller in callStatic is the SDK's connected signer and not the admin contract, the estimateGas method throws.
  // const gasForAdminTransaction = await accountContract.estimator.gasLimitOf("execute", [accountTransactionParams, signaturForTransactionParams]);

  const relayRequestParams = {
    signer: createParams.signer,
    accountId: createParams.accountId,
    value: 0,
    gas: 0,
    data: accountTransactionData,
  };

<<<<<<< HEAD
  const tx = await accountAdmin.call("relay", ...Object.values(relayRequestParams));
=======
  const signaturForTransactionRequest = await sdk.wallet.signTypedData(
    {
      name: "thirdwebWallet_Admin",
      version: "1",
      chainId,
      verifyingContract: WALLET_ADMIN,
    },
    { TransactionRequest: TransactionRequest },
    adminTransactionParams,
  );

  console.log("Signature for Wallet Admin calling execute: ", signaturForTransactionRequest);
  console.log("signaturForTransactionRequest", adminTransactionParams);

  const tx = await entrypoint.call("execute", adminTransactionParams, signaturForTransactionRequest);
>>>>>>> bee319365492a3d989b495b8e424fad82c5136ad

  console.log(tx);
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
