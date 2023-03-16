import CloneFactory from "../../artifacts_forge/TWStatelessFactory.sol/TWStatelessFactory.json";
import Forwarder from "../../artifacts_forge/Forwarder.sol/Forwarder.json";
import WETH from "../../artifacts_forge/WETH9.sol/WETH9.json";
import Stake721 from "../../artifacts_forge/NFTStake.sol/NFTStake.json";
import { readFileSync, writeFileSync } from "fs";
import { computeDeploymentAddress, constructKeylessTx } from "./keylessDeploy";
import { ethers as hardhatEthers } from "hardhat";

const contractsInfo = JSON.parse(readFileSync("scripts/keyless/InfraData.json", "utf-8"));

const coder = hardhatEthers.utils.defaultAbiCoder;

export async function generateInfraData() {
  // native token wrapper
  const nativeTokenTx = await constructKeylessTx(WETH.bytecode.object, []);
  const nativeTokenAddr = await computeDeploymentAddress(WETH.bytecode.object, []);
  contractsInfo.nativeTokenWrapper = {
    predictedAddress: nativeTokenAddr.predictedAddress,
    tx: nativeTokenTx.signedSerializedTestTx,
    from: nativeTokenTx.addr,
    deployData: nativeTokenAddr.deployData,
  };

  // forwarder
  const forwarderTx = await constructKeylessTx(Forwarder.bytecode.object, []);
  const forwarderAddr = await computeDeploymentAddress(Forwarder.bytecode.object, []);
  contractsInfo.forwarder = {
    predictedAddress: forwarderAddr.predictedAddress,
    tx: forwarderTx.signedSerializedTestTx,
    from: forwarderTx.addr,
    deployData: forwarderAddr.deployData,
  };

  // factory
  const factoryArgs = coder.encode(["address"], [forwarderAddr.predictedAddress]);
  const factoryTx = await constructKeylessTx(CloneFactory.bytecode.object, factoryArgs);
  const factoryAddr = await computeDeploymentAddress(CloneFactory.bytecode.object, factoryArgs);
  contractsInfo.cloneFactory = {
    predictedAddress: factoryAddr.predictedAddress,
    tx: factoryTx.signedSerializedTestTx,
    from: factoryTx.addr,
    deployData: factoryAddr.deployData,
  };

  // staking contract ERC721
  const stakeArgs = coder.encode(["address"], [nativeTokenAddr.predictedAddress]);
  const stakeTx = await constructKeylessTx(Stake721.bytecode.object, stakeArgs);
  const stakeAddr = await computeDeploymentAddress(Stake721.bytecode.object, stakeArgs);
  contractsInfo.stake721 = {
    predictedAddress: stakeAddr.predictedAddress,
    tx: stakeTx.signedSerializedTestTx,
    from: stakeTx.addr,
    deployData: stakeAddr.deployData,
  };

  writeFileSync("scripts/keyless/InfraData.json", JSON.stringify(contractsInfo), "utf-8");
}

generateInfraData()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
