import { Contract, ContractFactory } from "@ethersproject/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

async function main() {
  // Get signer
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  // Deploy contract
  const MintableERC20Permit_Factory: ContractFactory = await ethers.getContractFactory("MintableERC20Permit");
  const mintableERC20Permit: Contract = await MintableERC20Permit_Factory.connect(deployer).deploy();

  console.log(
    `Deploying MintableERC20Permit at ${mintableERC20Permit.address} | tx hash ${mintableERC20Permit.deployTransaction.hash}`,
  );

  await mintableERC20Permit.deployed();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
