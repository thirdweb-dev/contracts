import { ethers } from "hardhat";

// Contract types
import { ThirdwebFees } from "typechain/ThirdwebFees";
import { ThirdwebFactory } from "typechain/ThirdwebFactory";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

async function main() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  // Deploy ThirdwebFactory and ThirdwebRegistry
  const thirdwebFactory: ThirdwebFactory = await ethers.getContractFactory("ThirdwebFactory").then(f => f.deploy());

  console.log("Deploying ThirdwebFactory and ThirdwebRegistry tx: ", thirdwebFactory.deployTransaction.hash);
  await thirdwebFactory.deployTransaction.wait();

  console.log("ThirdwebFactory address: ", thirdwebFactory.address);
  console.log("ThirdwebRegistry address: ", await thirdwebFactory.thirdwebRegistry());

  // Deploy ThirdwebFees
  const defaultBpsSales = 0;
  const defaultBpsRoyalty = 0;

  const defaultRecipientRoyalty = deployer.address;
  const defaultRecipientSales = deployer.address;

  const thirdwebFees: ThirdwebFees = await ethers
    .getContractFactory("ThirdwebFees")
    .then(f => f.deploy(defaultBpsRoyalty, defaultRecipientRoyalty, defaultBpsSales, defaultRecipientSales));

  console.log("Deploying ThirdwebFees tx: ", thirdwebFees.deployTransaction.hash);
  await thirdwebFees.deployTransaction.wait();

  console.log("ThirdwebFees address: ", thirdwebFees.address);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
