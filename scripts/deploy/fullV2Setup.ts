import hre, { ethers } from "hardhat";

// Contract types
import { TWFee } from "typechain/TWFee";
import { TWFactory } from "typechain/TWFactory";

// General Types
import { DropERC721 } from "typechain/DropERC721";
import { DropERC1155 } from "typechain/DropERC1155";
import { TokenERC20 } from "typechain/TokenERC20";
import { TokenERC721 } from "typechain/TokenERC721";
import { TokenERC1155 } from "typechain/TokenERC1155";
import { Marketplace, Split, VoteERC20 } from "typechain";

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
  // Constructor args

  const nativeTokenWrapper: Record<number, string> = {
    1: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    4: "0xc778417E063141139Fce010982780140Aa0cD5Ab", // rinkeby
    5: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6", // goerli
    137: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
    80001: "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
    43114: "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
    43113: "0xd00ae08403B9bbb9124bB305C09058E32C39A48c",
    250: "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83",
    4002: "0xf1277d1Ed8AD466beddF92ef448A132661956621",
  };

  // Deploy FeeType
  const options = {
    //maxFeePerGas: ethers.utils.parseUnits("50", "gwei"),
    //maxPriorityFeePerGas: ethers.utils.parseUnits("50", "gwei"),
    //gasPrice: ethers.utils.parseUnits("100", "gwei"),
    gasLimit: 6_500_000,
  };

  const trustedForwarder = await (await ethers.getContractFactory("Forwarder")).deploy(options);
  //const trustedForwarder = await ethers.getContractAt("Forwarder", "0x8cbc8b5d71702032904750a66aefe8b603ebc538");
  console.log("Deploying Trusted Forwarder at tx: ", trustedForwarder.deployTransaction?.hash);
  await trustedForwarder.deployed();
  console.log("Trusted Forwarder address: ", trustedForwarder.address);

  const trustedForwarderAddress: string = trustedForwarder.address;

  // Deploy TWRegistry
  const thirdwebRegistry = await (
    await ethers.getContractFactory("TWRegistry")
  ).deploy(trustedForwarderAddress, options);
  //const thirdwebRegistry = await ethers.getContractAt("TWRegistry", "0x7c487845f98938Bb955B1D5AD069d9a30e4131fd");
  console.log("Deploying TWRegistry at tx: ", thirdwebRegistry.deployTransaction?.hash);
  await thirdwebRegistry.deployed();
  console.log("TWRegistry address: ", thirdwebRegistry.address);

  // Deploy TWFactory and TWRegistry
  const thirdwebFactory = await (
    await ethers.getContractFactory("TWFactory")
  ).deploy(trustedForwarderAddress, thirdwebRegistry.address, options);
  //const thirdwebFactory = await ethers.getContractAt("TWFactory", "0xd24b3de085CFd8c54b94feAD08a7962D343E6DE0");
  console.log("Deploying TWFactory at tx: ", thirdwebFactory.deployTransaction?.hash);
  await thirdwebFactory.deployed();
  console.log("TWFactory address: ", thirdwebFactory.address);

  // Deploy TWFee
  const thirdwebFee: TWFee = await ethers
    .getContractFactory("TWFee")
    .then(f => f.deploy(trustedForwarderAddress, thirdwebFactory.address, options));
  //const thirdwebFee = await ethers.getContractAt("TWFee", "0x8C4B615040Ebd2618e8fC3B20ceFe9abAfdEb0ea");
  console.log("Deploying TWFee at tx: ", thirdwebFee.deployTransaction?.hash);
  await thirdwebFee.deployed();
  console.log("TWFee address: ", thirdwebFee.address);

  // Deploy a test implementation: Drop721
  const drop721: DropERC721 = await ethers
    .getContractFactory("DropERC721")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  //const drop721 = await ethers.getContractAt("DropERC721", "0xcF4c511551aE4dab1F997866FC3900cd2aaeC40D");
  console.log("Deploying DropERC721 at tx: ", drop721.deployTransaction?.hash);
  console.log("DropERC721 address: ", drop721.address);

  // Deploy a test implementation: Drop1155
  const drop1155: DropERC1155 = await ethers
    .getContractFactory("DropERC1155")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying Drop1155 at tx: ", drop1155.deployTransaction.hash);
  console.log("Drop1155 address: ", drop1155.address);

  // Deploy a test implementation: TokenERC20
  const tokenERC20: TokenERC20 = await ethers
    .getContractFactory("TokenERC20")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying TokenERC20 at tx: ", tokenERC20.deployTransaction.hash);
  console.log("TokenERC20 address: ", tokenERC20.address);

  // Set the deployed `TokenERC20` as an approved module in TWFactory

  // Deploy a test implementation: TokenERC721
  const tokenERC721: TokenERC721 = await ethers
    .getContractFactory("TokenERC721")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying TokenERC721 at tx: ", tokenERC721.deployTransaction.hash);
  console.log("TokenERC721 address: ", tokenERC721.address);

  // Set the deployed `TokenERC721` as an approved module in TWFactory
  // Deploy a test implementation: TokenERC1155
  const tokenERC1155: TokenERC1155 = await ethers
    .getContractFactory("TokenERC1155")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying TokenERC1155 at tx: ", tokenERC1155.deployTransaction.hash);
  console.log("TokenERC1155 address: ", tokenERC1155.address);

  const split: Split = await ethers
    .getContractFactory("Split")
    .then(f => f.deploy(thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying Split at tx: ", split.deployTransaction.hash);
  console.log("Split address: ", split.address);

  const marketplace: Marketplace = await ethers
    .getContractFactory("Marketplace")
    .then(f => f.deploy(nativeTokenWrapper[ethers.provider.network.chainId], thirdwebFee.address, options))
    .then(f => f.deployed());
  console.log("Deploying Marketplace at tx: ", marketplace.deployTransaction.hash);
  console.log("Marketplace address: ", marketplace.address);

  const vote: VoteERC20 = await ethers
    .getContractFactory("VoteERC20")
    .then(f => f.deploy(options))
    .then(f => f.deployed());
  console.log("Deploying vote at tx: ", vote.deployTransaction.hash);
  console.log("Vote address: ", vote.address);

  const tx = await thirdwebFactory.multicall(
    [
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [drop721.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [drop1155.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [tokenERC20.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [tokenERC721.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [tokenERC1155.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [split.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [marketplace.address]),
      thirdwebFactory.interface.encodeFunctionData("addImplementation", [vote.address]),
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
  await verify(drop721.address, [thirdwebFee.address]);
  await verify(drop1155.address, [thirdwebFee.address]);
  await verify(tokenERC20.address, [thirdwebFee.address]);
  await verify(tokenERC721.address, [thirdwebFee.address]);
  await verify(tokenERC1155.address, [thirdwebFee.address]);
  await verify(split.address, [thirdwebFee.address]);
  await verify(vote.address, []);
  await verify(marketplace.address, [nativeTokenWrapper[ethers.provider.network.chainId], thirdwebFee.address]);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
