import hre, { ethers } from "hardhat";

import {
  DropERC1155,
  DropERC20,
  DropERC721,
  Marketplace,
  Multiwrap,
  SignatureDrop,
  Split,
  TokenERC1155,
  TokenERC20,
  TokenERC721,
  TWFee,
  VoteERC20,
} from "typechain";
import { nativeTokenWrapper } from "../../utils/nativeTokenWrapper";

async function verify(address: string, args: any[]) {
  try {
    return await hre.run("verify:verify", {
      address: address,
      constructorArguments: args,
    });
  } catch (e) {
    console.log(address, args, e);
  }
}

async function main() {
  // Deploy FeeType
  const options = {
    //maxFeePerGas: ethers.utils.parseUnits("50", "gwei"),
    //maxPriorityFeePerGas: ethers.utils.parseUnits("50", "gwei"),
    //gasPrice: ethers.utils.parseUnits("100", "gwei"),
    gasLimit: 5_000_000,
  };

  const trustedForwarder = await (await ethers.getContractFactory("Forwarder")).deploy(options);
  // const trustedForwarder = await ethers.getContractAt("Forwarder", "0x8cbc8B5d71702032904750A66AEfE8B603eBC538");
  console.log("Deploying Trusted Forwarder at tx: ", trustedForwarder.deployTransaction?.hash);
  await trustedForwarder.deployed();
  console.log("Trusted Forwarder address: ", trustedForwarder.address);
  const trustedForwarderAddress: string = trustedForwarder.address;

  // // Deploy TWRegistry
  const thirdwebRegistry = await (
    await ethers.getContractFactory("TWRegistry")
  ).deploy(trustedForwarderAddress, options);
  // const thirdwebRegistry = await ethers.getContractAt("TWRegistry", "0x7c487845f98938Bb955B1D5AD069d9a30e4131fd");
  console.log("Deploying TWRegistry at tx: ", thirdwebRegistry.deployTransaction?.hash);
  await thirdwebRegistry.deployed();
  console.log("TWRegistry address: ", thirdwebRegistry.address);

  // Deploy TWFactory and TWRegistry
  const thirdwebFactory = await (
    await ethers.getContractFactory("TWFactory")
  ).deploy(trustedForwarderAddress, thirdwebRegistry.address, options);
  // const thirdwebFactory = await ethers.getContractAt("TWFactory", "0xd24b3de085CFd8c54b94feAD08a7962D343E6DE0");
  console.log("Deploying TWFactory at tx: ", thirdwebFactory.deployTransaction?.hash);
  await thirdwebFactory.deployed();
  console.log("TWFactory address: ", thirdwebFactory.address);

  // Deploy TWFee
  const thirdwebFee: TWFee = await ethers
    .getContractFactory("TWFee")
    .then(f => f.deploy(trustedForwarderAddress, thirdwebFactory.address, options));
  // const thirdwebFee = await ethers.getContractAt("TWFee", "0x8C4B615040Ebd2618e8fC3B20ceFe9abAfdEb0ea");
  console.log("Deploying TWFee at tx: ", thirdwebFee.deployTransaction?.hash);
  await thirdwebFee.deployed();
  console.log("TWFee address: ", thirdwebFee.address);

  // Deploy a test implementation: Drop721
  const drop721: DropERC721 = await ethers
    .getContractFactory("DropERC721")
    .then(f => f.deploy(options))
    .then(f => f.deployed());
  // const drop721 = await ethers.getContractAt("DropERC721", "0xcF4c511551aE4dab1F997866FC3900cd2aaeC40D");
  console.log("Deploying DropERC721 at tx: ", drop721.deployTransaction?.hash);
  console.log("DropERC721 address: ", drop721.address);

  // Deploy a test implementation: Drop1155
  const drop1155: DropERC1155 = await ethers
    .getContractFactory("DropERC1155")
    .then(f => f.deploy(options))
    .then(f => f.deployed());
  console.log("Deploying Drop1155 at tx: ", drop1155.deployTransaction.hash);
  console.log("Drop1155 address: ", drop1155.address);
  // const drop1155 = await ethers.getContractAt("DropERC1155", "0xb0435b47ad26115A39c59735b814f3769F07C2c1");

  // Deploy a test implementation: DropERC20
  const drop20: DropERC20 = await ethers
    .getContractFactory("DropERC20")
    .then(f => f.deploy(options))
    .then(f => f.deployed());
  console.log("Deploying DropERC20 at tx: ", drop20.deployTransaction.hash);
  console.log("DropERC20 address: ", drop20.address);
  // const drop20 = await ethers.getContractAt("DropERC20", "0x5bB3DCac11fa075D4f362Bb2D0De93fA821f1dA9");

  // Deploy a test implementation: TokenERC20
  const tokenERC20: TokenERC20 = await ethers
    .getContractFactory("TokenERC20")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying TokenERC20 at tx: ", tokenERC20.deployTransaction.hash);
  console.log("TokenERC20 address: ", tokenERC20.address);
  // const tokenERC20 = await ethers.getContractAt("TokenERC20", "0x0E1d366475709eF677275E4161a20456cAc2071f");

  // Deploy a test implementation: TokenERC721
  const tokenERC721: TokenERC721 = await ethers
    .getContractFactory("TokenERC721")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying TokenERC721 at tx: ", tokenERC721.deployTransaction.hash);
  console.log("TokenERC721 address: ", tokenERC721.address);
  // const tokenERC721 = await ethers.getContractAt("TokenERC721", "0x7185fBf58db5F3Df186197406CEc2E253A1f5fE6");

  // Deploy a test implementation: TokenERC1155
  const tokenERC1155: TokenERC1155 = await ethers
    .getContractFactory("TokenERC1155")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying TokenERC1155 at tx: ", tokenERC1155.deployTransaction.hash);
  console.log("TokenERC1155 address: ", tokenERC1155.address);
  // const tokenERC1155 = await ethers.getContractAt("TokenERC1155", "0xe9D53b11d6531b0E56990755a7856889FC59848d");

  const split: Split = await ethers
    .getContractFactory("Split")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying Split at tx: ", split.deployTransaction.hash);
  console.log("Split address: ", split.address);
  // const split = await ethers.getContractAt("Split", "0x83cCFAaA705Bf3B734B50121d47b82D58aE91796");

  const marketplace: Marketplace = await ethers
    .getContractFactory("Marketplace")
    .then(f => f.deploy(nativeTokenWrapper[ethers.provider.network.chainId], thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying Marketplace at tx: ", marketplace.deployTransaction.hash);
  console.log("Marketplace address: ", marketplace.address);
  // const marketplace = await ethers.getContractAt("Marketplace", "0x7181acA2A01Bc98596b1d5375C97389F0d136B2b");

  const vote: VoteERC20 = await ethers
    .getContractFactory("VoteERC20")
    .then(f => f.deploy(options))
    .then(f => f.deployed());
  console.log("Deploying vote at tx: ", vote.deployTransaction.hash);
  console.log("Vote address: ", vote.address);
  // const vote = await ethers.getContractAt("VoteERC20", "0x8F18067D118B1DD1D7a503B0b6Ed255341068029");

  // Multiwrap
  const multiwrap: Multiwrap = await ethers
    .getContractFactory("Multiwrap")
    .then(f => f.deploy(nativeTokenWrapper[ethers.provider.network.chainId], options))
    .then(f => f.deployed());
  console.log("Deploying Multiwrap at tx: ", multiwrap.deployTransaction.hash);
  console.log("Multiwrap address: ", multiwrap.address);
  // const multiwrap = await ethers.getContractAt("Multiwrap", "0x10C06F8B3695813276b4A921C06bb3b122aAf9d2");

  // Signature Drop
  const sigdrop: SignatureDrop = await ethers
    .getContractFactory("SignatureDrop")
    .then(f => f.deploy(options))
    .then(f => f.deployed());
  console.log("Deploying SignatureDrop at tx: ", sigdrop.deployTransaction.hash);
  console.log("SignatureDrop address: ", sigdrop.address);
  // const sigdrop = await ethers.getContractAt("SignatureDrop", "0xAC4190bFF783B19812137c38E7d3c724b655f1d5");

  // TODO Pack

  const tx = await thirdwebFactory.multicall(
    [
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [drop721.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [drop1155.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [drop20.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [tokenERC20.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [tokenERC721.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [tokenERC1155.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [split.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [marketplace.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [vote.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [multiwrap.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [sigdrop.address]),
    ],
    options,
  );
  console.log("Adding implementations at tx: ", tx.hash);
  await tx.wait();

  const tx2 = await thirdwebRegistry.grantRole(await thirdwebRegistry.OPERATOR_ROLE(), thirdwebFactory.address);
  await tx2.wait();
  console.log("grant role: ", tx2.hash);

  console.log("DONE. Now verifying contracts...");

  await verify(thirdwebRegistry.address, [trustedForwarderAddress]);
  await verify(thirdwebFactory.address, [trustedForwarderAddress, thirdwebRegistry.address]);
  await verify(thirdwebFee.address, [trustedForwarderAddress, thirdwebFactory.address]);
  await verify(drop721.address, []);
  await verify(drop1155.address, []);
  await verify(drop20.address, []);
  await verify(tokenERC20.address, [thirdwebFee.address]);
  await verify(tokenERC721.address, [thirdwebFee.address]);
  await verify(tokenERC1155.address, [thirdwebFee.address]);
  await verify(split.address, [thirdwebFee.address]);
  await verify(marketplace.address, [nativeTokenWrapper[ethers.provider.network.chainId], thirdwebFee.address]);
  await verify(vote.address, []);
  await verify(multiwrap.address, [nativeTokenWrapper[ethers.provider.network.chainId]]);
  await verify(sigdrop.address, []);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
