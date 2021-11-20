import hre, { ethers } from "hardhat";

async function verify() {
  // txhash = "0x8f71c6b772a20340d33a9695dc5de1c72eedf36016daebcaaa72cfffe2c17fd0";
  // type = "LazyNFT";
  const txhash = "0x8f71c6b772a20340d33a9695dc5de1c72eedf36016daebcaaa72cfffe2c17fd0";
  const type = "LazyNFT";

  const tx = await ethers.provider.getTransaction(txhash);
  const txdata = tx.data;
  const address = (tx as any).creates;
  const contract = await ethers.getContractFactory(type);
  // make sure that deployed bytecode matches with contract bytecode
  if (txdata.indexOf(contract.bytecode) === -1) {
    throw new Error("invalid contract bytecode");
  }
  const paramsData = `0x${txdata.substring(contract.bytecode.length)}`;
  const paramsDeployed = ethers.utils.defaultAbiCoder.decode(contract.interface.deploy.inputs, paramsData);
  const paramsArguments = paramsDeployed.toString().split(",");
  await hre.run("verify:verify", {
    address,
    constructorArguments: [...paramsArguments],
  });
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
