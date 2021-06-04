  
// Chainlink info for Rinkeby

const vrfCoordinator = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B'
const linkTokenAddress = '0x01be23585060835e02b77ef475b0cc51aa1e0709'
const keyHash = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311'

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const PackToken_Factory = await ethers.getContractFactory("Pack");
  const packToken = await PackToken_Factory.deploy(vrfCoordinator, linkTokenAddress, keyHash);

  console.log("Pack ERC1155 token address:", packToken.address);

  const PackMarket_Factory = await ethers.getContractFactory("PackMarket");
  const packMarket = await PackMarket_Factory.deploy(packToken.address);

  console.log("Pack Market address:", packMarket.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// Pack ERC1155 token address (Rinkeby) -- 0x6416795AF11336ef33EF7BAd1354F370141f8728
// Pack Market address (Rinkeby) -- 0x5c0Ad93A3580260820fDcD1E5F5fDD714DA800B7

// npx hardhat verify --network rinkeby 0x6416795AF11336ef33EF7BAd1354F370141f8728 "0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B" "0x01be23585060835e02b77ef475b0cc51aa1e0709" "0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311"
// npx hardhat verify --network rinkeby 0x5c0Ad93A3580260820fDcD1E5F5fDD714DA800B7 "0x6416795AF11336ef33EF7BAd1354F370141f8728"