import "dotenv/config";
// import { BigNumber } from "ethers";
import { BigNumber, BytesLike, ethers } from "ethers";
import { readFileSync } from "fs";
import { ethers as hardhatEthers } from "hardhat";
import ExtensionRegistry from "../../artifacts_forge/ExtensionRegistry.sol/ExtensionRegistry.json";
import NFTStakeAbi from "../../artifacts_forge/NFTStake.sol/NFTStake.json";
import { TWStatelessFactory, NFTStake } from "typechain";

type InfraTxInfo = {
  predictedAddress: string;
  tx: string;
  from: string;
  deployData: string;
};

const infraContracts = JSON.parse(readFileSync("scripts/keyless/InfraData.json", "utf-8"));

const coder = hardhatEthers.utils.defaultAbiCoder;

const customSigInfo = {
  v: 27,
  r: "0x2222222222222222222222222222222222222222222222222222222222222222",
  s: "0x2222222222222222222222222222222222222222222222222222222222222222",
};
export const commonFactory = "0x4e59b44847b379578588920cA78FbF26c0B4956C";

export async function deployCommonFactory(signer: any) {
  let factoryCode = await hardhatEthers.provider.getCode(commonFactory);
  // deploy community factory if not already deployed
  if (factoryCode == "0x") {
    console.log("zero code");
    // send balance
    let refundTx = {
      to: "3fab184622dc19b6109349b94811493bf2a45362",
      value: hardhatEthers.utils.parseEther("0.01"),
    };
    await signer.sendTransaction(refundTx);

    // deploy
    try {
      const tx = await hardhatEthers.provider.sendTransaction(
        "0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222",
      );
    } catch (err) {
      console.log("Couldn't deploy factory");
      console.log(err);
      process.exit(1);
    }

    // check
    factoryCode = await hardhatEthers.provider.getCode(commonFactory);
    console.log("deployed code: ", factoryCode);
  }
}

export async function constructKeylessTx(bytecode: any, args: any) {
  const bytecodeHash = hardhatEthers.utils.id(bytecode);
  const salt = `tw.${bytecodeHash}`;
  const saltHash = hardhatEthers.utils.id(salt);

  const data = hardhatEthers.utils.solidityPack(["bytes32", "bytes", "bytes"], [saltHash, bytecode, args]);

  const testTx = {
    gasPrice: 10 * 10 ** 9,
    gasLimit: 5000000,
    to: commonFactory,
    value: 0,
    nonce: 0,
    data: data,
  };
  const customSignature = ethers.utils.joinSignature(customSigInfo);
  const serializedTestTx = ethers.utils.serializeTransaction(testTx);

  const addr = ethers.utils.recoverAddress(
    ethers.utils.arrayify(ethers.utils.keccak256(serializedTestTx)),
    customSignature,
  );

  const signedSerializedTestTx = ethers.utils.serializeTransaction(testTx, customSigInfo);

  return {
    addr,
    signedSerializedTestTx,
  };
}

export async function computeDeploymentAddress(bytecode: any, args: any) {
  const bytecodeHash = hardhatEthers.utils.id(bytecode);
  const salt = `tw.${bytecodeHash}`;
  const saltHash = hardhatEthers.utils.id(salt);

  const deployData = hardhatEthers.utils.solidityPack(["bytes32", "bytes", "bytes"], [saltHash, bytecode, args]);

  const initBytecode = hardhatEthers.utils.solidityPack(["bytes", "bytes"], [bytecode, args]);
  const deployInfoPacked = hardhatEthers.utils.solidityPack(
    ["bytes1", "address", "bytes32", "bytes32"],
    ["0xff", commonFactory, saltHash, hardhatEthers.utils.solidityKeccak256(["bytes"], [initBytecode])],
  );
  const addr = hardhatEthers.utils.solidityKeccak256(["bytes"], [deployInfoPacked]);

  return { predictedAddress: `0x${addr.slice(26)}`, deployData };
}

async function deployInfraKeyless() {
  const [signer] = await hardhatEthers.getSigners();

  // create2 factory
  await deployCommonFactory(signer);

  const feeData = await hardhatEthers.provider.getFeeData();
  for (let txInfo of Object.values(infraContracts) as InfraTxInfo[]) {
    const code = await hardhatEthers.provider.getCode(txInfo.predictedAddress);
    if (code === "0x") {
      const requiredGas = await hardhatEthers.provider.estimateGas({
        to: commonFactory,
        data: txInfo.deployData,
      });
      // ===
      const testTx = {
        gasPrice: feeData.maxFeePerGas?.toNumber(),
        gasLimit: requiredGas.toNumber(),
        to: commonFactory,
        value: 0,
        nonce: 0,
        data: txInfo.deployData,
      };
      const customSignature = ethers.utils.joinSignature(customSigInfo);
      const serializedTestTx = ethers.utils.serializeTransaction(testTx);

      const addr = ethers.utils.recoverAddress(
        ethers.utils.arrayify(ethers.utils.keccak256(serializedTestTx)),
        customSignature,
      );

      const signedSerializedTestTx = ethers.utils.serializeTransaction(testTx, customSigInfo);
      // ===

      let fundAddr = {
        to: addr,
        value: requiredGas
          .mul(feeData.maxFeePerGas || 1)
          .mul(105)
          .div(100),
      };
      await signer.sendTransaction(fundAddr);

      console.log("deploying -- ");
      console.log("required gas: ", ethers.utils.formatEther(requiredGas));
      console.log("estimated cost: ", ethers.utils.formatEther(requiredGas.mul(feeData.maxFeePerGas || 1)));
      console.log(
        `${txInfo.from} balance before: `,
        ethers.utils.formatEther(await hardhatEthers.provider.getBalance(addr)),
      );
      await (await hardhatEthers.provider.sendTransaction(signedSerializedTestTx)).wait();
      console.log(
        `${txInfo.from} balance after: `,
        ethers.utils.formatEther(await hardhatEthers.provider.getBalance(addr)),
      );
      console.log("");
    }
  }
}

async function deployInfraWithSigner() {
  const [signer] = await hardhatEthers.getSigners();

  // create2 factory
  await deployCommonFactory(signer);

  for (let txInfo of Object.values(infraContracts) as InfraTxInfo[]) {
    // get init bytecode
    const deployData = txInfo.deployData;

    const tx = {
      from: signer.address,
      to: commonFactory,
      value: 0,
      nonce: await signer.getTransactionCount("latest"),
      data: deployData,
    };

    await (await signer.sendTransaction(tx)).wait();
  }
}

async function deployStaking() {
  await deployInfraKeyless();
  // await deployInfraWithSigner();

  const cloneFactory: TWStatelessFactory = await hardhatEthers.getContractAt(
    "TWStatelessFactory",
    infraContracts.cloneFactory.predictedAddress as string,
  );

  let stakingInterface = new ethers.utils.Interface(NFTStakeAbi.abi);
  let encodedFunctionData = stakingInterface.encodeFunctionData("initialize", [
    "0xdd99b75f095d0c4d5112aCe938e4e6ed962fb024",
    "",
    [],
    "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    "0xdd99b75f095d0c4d5112aCe938e4e6ed962fb024",
    1000,
    1,
  ]);
  const deployProxy = await cloneFactory.deployProxyByImplementation(
    infraContracts.stake721.predictedAddress,
    encodedFunctionData,
    ethers.utils.id("salt123"),
  );
  const receipt = await deployProxy.wait();
  if (receipt.events) {
    const args = receipt.events[0].args;
    if (args) {
      const stakingContract: NFTStake = await hardhatEthers.getContractAt("NFTStake", args[1] as string);
      const contractVersion = await stakingContract.contractVersion();
      console.log("staking contract version: ", contractVersion);
      console.log("reward token: ", await stakingContract.rewardToken());
    }
  }
}

async function main() {
  const [signer] = await hardhatEthers.getSigners();
  await deployCommonFactory(signer);
  // ExtensionRegistry deployment here
  const args = coder.encode(["address"], ["0xdd99b75f095d0c4d5112aCe938e4e6ed962fb024"]);
  const { addr, signedSerializedTestTx } = await constructKeylessTx(ExtensionRegistry.bytecode.object, args);

  console.log("addr: ", addr);
  console.log("addr balance: ", await hardhatEthers.provider.getBalance(addr));

  let fundAddr = {
    to: addr,
    value: hardhatEthers.utils.parseEther("1"),
  };
  await signer.sendTransaction(fundAddr);
  console.log("addr balance new: ", await hardhatEthers.provider.getBalance(addr));

  const predictedAddress = (await computeDeploymentAddress(ExtensionRegistry.bytecode.object, args)).predictedAddress;
  console.log("predicted address: ", predictedAddress);

  const receipt = await hardhatEthers.provider.sendTransaction(signedSerializedTestTx);
  const deployTx = await receipt.wait();
  console.log("logs: ", deployTx);
  // console.log("code: ", await hardhatEthers.provider.getCode(predictedAddress));
  console.log("encoded args: ", args);

  await deployStaking();
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });

async function writeFactoryDeployerTransaction(deploymentBytecode: any) {
  const deploymentGas = 100000;

  const wallet = new ethers.Wallet("0xdf110a5c824f5a6a932b8c6dac0c787e0eb0e5cd2d3790e407487b020eacc48a");
  console.log("ADDRESS", wallet.address);

  const tx = {
    gasPrice: 2000000000,
    gasLimit: 21000,
    to: "0x3e245df5a4de41e65cecd1f98b96ca06c3d319f0",
    value: ethers.utils.parseEther("0.02"),
    nonce: 0,
    data: undefined,
    chainId: 3,
  };

  const signedTx = await wallet.signTransaction(tx);
  const parsed = ethers.utils.parseTransaction(signedTx);
  console.log("parsed: ", parsed);

  const signature = ethers.utils.joinSignature({ r: parsed.r as string, s: parsed.s, v: parsed.v });
  console.log("signature: ", signature);

  const serializedTransaction = ethers.utils.serializeTransaction(tx);
  console.log("serialized: ", serializedTransaction);
  // "0xea808477359400825208943e245df5a4de41e65cecd1f98b96ca06c3d319f087470de4df82000080038080"

  const signedSerialized = ethers.utils.serializeTransaction(tx, signature);
  console.log("signed and serialized: ", signedSerialized);
  // "0xf86a808477359400825208943e245df5a4de41e65cecd1f98b96ca06c3d319f087470de4df820000802aa02e1fe98e926f10eeca5dd6d690fa5b24c026c46287c3f1a729ca2c596f3a772ea04bd2d5fde3b848d58b45f958276b63ff54846fc9329dc68e9822c7fb699e9adf"

  console.log("decoded: ", ethers.utils.parseTransaction(signedSerialized));

  const serializedTxHash = ethers.utils.keccak256(serializedTransaction);
  // console.log("serialized Tx Hash: ", serializedTxHash);
  const serializedTxBytes = ethers.utils.arrayify(serializedTxHash); // create binary hash
  // console.log("serialized bytes: ", serializedTxBytes);
  const recoveredPubKey = ethers.utils.recoverPublicKey(serializedTxBytes, signature);
  const recoveredAddress = ethers.utils.recoverAddress(serializedTxBytes, signature);
  console.log();
  console.log("recovered address: ", recoveredAddress);

  // arachnid community factory: construct same tx using ethers
  const customSigInfo = {
    v: 27,
    r: "0x2222222222222222222222222222222222222222222222222222222222222222",
    s: "0x2222222222222222222222222222222222222222222222222222222222222222",
  };
  const testTx = {
    gasPrice: 100 * 10 ** 9,
    gasLimit: 100000,
    value: 0,
    nonce: 0,
    data: "0x604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3",
  };
  const customSignature = ethers.utils.joinSignature(customSigInfo);
  const serializedTestTx = ethers.utils.serializeTransaction(testTx);
  console.log("parsed test tx: ", ethers.utils.parseTransaction(serializedTestTx));
  const addr = ethers.utils.recoverAddress(
    ethers.utils.arrayify(ethers.utils.keccak256(serializedTestTx)),
    customSignature,
  );
  console.log("addr: ", addr);
  console.log("serialized test tx: ", serializedTestTx);
  const signSerializedTestTx = ethers.utils.serializeTransaction(testTx, customSigInfo);
  console.log("serialize test tx with sig: ", signSerializedTestTx);
}
