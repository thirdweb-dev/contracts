import "dotenv/config";
// import { BigNumber } from "ethers";
import { BigNumber, BytesLike, ethers } from "ethers";
import { ethers as hardhatEthers } from "hardhat";
import ExtensionRegistry from "../../artifacts_forge/ExtensionRegistry.sol/ExtensionRegistry.json";

const coder = hardhatEthers.utils.defaultAbiCoder;

const customSigInfo = {
  v: 27,
  r: "0x2222222222222222222222222222222222222222222222222222222222222222",
  s: "0x2222222222222222222222222222222222222222222222222222222222222222",
};
const commonFactory = "0x4e59b44847b379578588920cA78FbF26c0B4956C";

async function deployCommonFactory(signer: any) {
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

async function constructKeylessTx(bytecode: any, args: any) {
  const bytecodeHash = hardhatEthers.utils.id(bytecode);
  const salt = `tw.${bytecodeHash}`;
  const saltHash = hardhatEthers.utils.id(salt);

  const data = hardhatEthers.utils.solidityPack(["bytes32", "bytes", "bytes"], [saltHash, bytecode, args]);

  const testTx = {
    gasPrice: 100 * 10 ** 9,
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

async function computeDeploymentAddress(bytecode: any, args: any) {
  const bytecodeHash = hardhatEthers.utils.id(bytecode);
  const salt = `tw.${bytecodeHash}`;
  const saltHash = hardhatEthers.utils.id(salt);

  const initBytecode = hardhatEthers.utils.solidityPack(["bytes", "bytes"], [bytecode, args]);
  const deployInfoPacked = hardhatEthers.utils.solidityPack(
    ["bytes1", "address", "bytes32", "bytes32"],
    ["0xff", commonFactory, saltHash, hardhatEthers.utils.solidityKeccak256(["bytes"], [initBytecode])],
  );
  const predictedAddress = hardhatEthers.utils.solidityKeccak256(["bytes"], [deployInfoPacked]);

  return `0x${predictedAddress.slice(26)}`;
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

  const predictedAddress = await computeDeploymentAddress(ExtensionRegistry.bytecode.object, args);
  console.log("predicted address: ", predictedAddress);

  const receipt = await hardhatEthers.provider.sendTransaction(signedSerializedTestTx);
  const deployTx = await receipt.wait();
  console.log("logs: ", deployTx);
  // console.log("code: ", await hardhatEthers.provider.getCode(predictedAddress));
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
