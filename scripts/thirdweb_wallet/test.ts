import { ethers } from "ethers";
import { ThirdwebSDK } from "@thirdweb-dev/sdk";
import { readFileSync } from "fs";

// import { WalletEntrypoint } from "typechain";

import dotenv from "dotenv";
dotenv.config();

const CreateAccountParams = [
    { name: "signer", type: "address" },
    { name: "credentials", type: "bytes32" },
    { name: "deploymentSalt", type: "bytes32" },
    { name: "initialAccountBalance", type: "uint256" },
    { name: "validityStartTimestamp", type: "uint128" },
    { name: "validityEndTimestamp", type: "uint128" }
]

const TransactionParams = [
    { name: "target", type: "address" },
    { name: "data", type: "bytes" },
    { name: "nonce", type: "uint256" },
    { name: "value", type: "uint256" },
    { name: "gas", type: "uint256" },
    { name: "validityStartTimestamp", type: "uint128" },
    { name: "validityEndTimestamp", type: "uint128" }
]

const TransactionRequest = [
    { name: "signer", type: "address" },
    { name: "credentials", type: "bytes32" },
    { name: "value", type: "uint256" },
    { name: "gas", type: "uint256" },
    { name: "data", type: "bytes" },
    { name: "validityStartTimestamp", type: "uint128" },
    { name: "validityEndTimestamp", type: "uint128" }
]

async function main() {

    /*///////////////////////////////////////////////////////////////
                    Connect to WalletEntrypoint
    //////////////////////////////////////////////////////////////*/

    const WALLET_ADMIN: string = "0xb82d2f432A489b629f5574Bc7FcDEa4a9D2a9a99";
    
    const sdk = ThirdwebSDK.fromPrivateKey(
        process.env.THIRDWEB_WALLET_TEST_PKEY as string,
        "goerli"
    );
    // const entrypoint = await sdk.getContract(WALLET_ADMIN); 
    const entrypoint = await sdk.getContractFromAbi(
        WALLET_ADMIN,
          JSON.parse(readFileSync("artifacts_forge/WalletEntrypoint.sol/WalletEntrypoint.json", "utf-8")).abi,
        );

    /*///////////////////////////////////////////////////////////////
            Create an account / get an account for signer
    //////////////////////////////////////////////////////////////*/

    const username = "test_user";
    const password = "super_secret";

    const createParams = {
        signer: await sdk.wallet.getAddress(),
        credentials: ethers.utils.solidityKeccak256(["string", "string"], [username, password]),
        deploymentSalt: ethers.utils.formatBytes32String("randomSaltSalt"),
        initialAccountBalance: 0,
        validityStartTimestamp: 0,
        validityEndTimestamp: Math.floor(Date.now() / 1000) + 10_000
    };

    const wrapper = (entrypoint as any).contractWrapper;
    const chainId = await wrapper.getChainID();
    
    const signaturForCreateAccount = await wrapper.signTypedData(
        sdk.getSigner(),
        {
          name: "thirdwebWallet_Admin",
          version: "1",
          chainId,
          verifyingContract: WALLET_ADMIN,
        },
        { CreateAccountParams: CreateAccountParams },
        createParams,
    );
    
    // console.log("\nSignature generated for account creation: ", signaturForCreateAccount);
    
    // entrypoint.interceptor.overrideNextTransaction(() => {
    //     return { gasLimit: 200_000 }
    // });
    // await entrypoint.call("createAccount", createParams, signaturForCreateAccount);

    const signerCredentialPair = ethers.utils.solidityKeccak256(["bytes"], [ethers.utils.defaultAbiCoder.encode(["address", "bytes32"], [createParams.signer, createParams.credentials])]);
    const accountAddress: string = await entrypoint.call("accountOf", signerCredentialPair);

    console.log("Your account is: ", accountAddress); // 0x5dc4f80847DB26d296583e533857d087EC1dDf6e


    /*///////////////////////////////////////////////////////////////
                Perforfming a smart contract interaction
    //////////////////////////////////////////////////////////////*/

    const TOKEN_ADDRESS = "0xD5B9182069AAA1572A1EDCA9aFB00326E634651B";
    const tokenContract = await sdk.getContract(TOKEN_ADDRESS);

    const accountContract = await sdk.getContract(accountAddress, JSON.parse(readFileSync("artifacts_forge/Wallet.sol/Wallet.json", "utf-8")).abi);
    const nonce = await accountContract.call("nonce");

    console.log("Account nonce: ", nonce);
    
    const gasForAccountTransaction = await tokenContract.estimator.gasLimitOf("mintTo", [accountAddress, ethers.utils.parseEther("1")]);

    const accountTransactionParams = {
        target: TOKEN_ADDRESS,
        data: tokenContract.encoder.encode("mintTo", [accountAddress, ethers.utils.parseEther("1")]),
        nonce: nonce,
        value: 0,
        gas: gasForAccountTransaction.add(50_000),
        validityStartTimestamp: 0,
        validityEndTimestamp: Math.floor(Date.now() / 1000) + 10_000
    }

    const signaturForTransactionParams = await wrapper.signTypedData(
        sdk.getSigner(),
        {
          name: "thirdwebWallet",
          version: "1",
          chainId,
          verifyingContract: accountAddress,
        },
        { TransactionParams: TransactionParams },
        accountTransactionParams,
    );

    console.log("Signature for Wallet calling mintTo: ", signaturForTransactionParams);

    const accountTransactionData = accountContract.encoder.encode(("execute"), [accountTransactionParams, signaturForTransactionParams]);

    // NOTE: since the caller in callStatic is the SDK's connected signer and not the admin contract, the estimateGas method throws.
    // const gasForAdminTransaction = await accountContract.estimator.gasLimitOf("execute", [accountTransactionParams, signaturForTransactionParams]);

    const adminTransactionParams = {
        signer: createParams.signer,
        credentials: createParams.credentials,
        value: 0,
        gas: 200_000,
        data: accountTransactionData,
        validityStartTimestamp: 0,
        validityEndTimestamp: Math.floor(Date.now() / 1000) + 10_000
    }

    const signaturForTransactionRequest = await wrapper.signTypedData(
        sdk.getSigner(),
        {
          name: "thirdwebWallet_Admin",
          version: "1",
          chainId,
          verifyingContract: WALLET_ADMIN,
        },
        { TransactionRequest: TransactionRequest },
        adminTransactionParams,
    );
    
    console.log("Signature for Wallet Admin calling Wallet: ", signaturForTransactionRequest);
    console.log(adminTransactionParams);
    
    entrypoint.interceptor.overrideNextTransaction(() => {
        return { gasLimit: 600_000 }
    });
    const tx = await entrypoint.call("execute", adminTransactionParams, signaturForTransactionRequest);

    console.log(tx);
}

main()
.then(() => process.exit(0))
.catch(err => {
  console.error(err);
  process.exit(1);
});
