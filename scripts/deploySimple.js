async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );
  
  console.log("Account balance:", (await deployer.getBalance()).toString());

//   const PackToken_Factory = await ethers.getContractFactory("Pack");
//   const packToken = await PackToken_Factory.deploy();

//   console.log("Pack ERC1155 token address:", packToken.address);

  const PackMarket_Factory = await ethers.getContractFactory("PackMarket");
//   const packMarket = await PackMarket_Factory.deploy(packToken.address);
  const packMarket = await PackMarket_Factory.deploy("0xac063C80a70725e3c63FaaC04a10920596cd9255");

  console.log("Pack Market address:", packMarket.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// Pack ERC1155 token address (Rinkeby) -- 0xac063C80a70725e3c63FaaC04a10920596cd9255
// Pack Market address -- 0x2B349ED5446E6882312DCD2876f299F18185020a