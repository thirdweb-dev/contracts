async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );
  
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const PackToken_Factory = await ethers.getContractFactory("Pack");
  const packToken = await PackToken_Factory.deploy();

  console.log("Pack ERC1155 token address:", packToken.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// Pack ERC1155 token address (Rinkeby) -- 0x62d1A5A62f5B8F610B0C2526A765D1364B79dEd6