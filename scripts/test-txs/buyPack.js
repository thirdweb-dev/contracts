require('dotenv').config();
const { ethers } = require("ethers");

// Get contract ABIs
const packTokenABI = require('../../abi/Pack.json')
const packMarketABI = require('../../abi/PackMarket.json');
const packCoinABI = require('../../abi/PackCoin.json');

// Set up wallet.
const privateKey = process.env.TEST_PRIVATE_KEY_SECONDARY;
const coinAdminPrivateKey = process.env.TEST_PRIVATE_KEY;
const alchemyEndpoint = process.env.ALCHEMY_ENDPOINT;

const provider = new ethers.providers.JsonRpcProvider(alchemyEndpoint, 'rinkeby');
const wallet = new ethers.Wallet(privateKey, provider)
const deployerWallet = new ethers.Wallet(coinAdminPrivateKey, provider)

// Set up contracts
const packTokenAddress = '0x0c56B393043CDA7c726c27FdD64Bd9262428515F'
const packMarketAddress = '0x24574D0C177ad9E5cD74d9dBF5a9A729924e72e2'
const packCoinAddress = '0x49e7f00ee5652523fAdE13674100c8518d7DA8b6'

const packToken = new ethers.Contract(packTokenAddress, packTokenABI, wallet);
const packMarket = new ethers.Contract(packMarketAddress, packMarketABI, wallet);
const packCoin = new ethers.Contract(packCoinAddress, packCoinABI, wallet);
const deployerPackCoin = new ethers.Contract(packCoinAddress, packCoinABI, deployerWallet);

let targetTokenId = 6;

async function main(tokenId) {
  const listingInfo = await packMarket.listings(
    '0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372',
    tokenId
  )

  if(listingInfo.currency == packCoinAddress) {
    const mintTx = await deployerPackCoin.mint(wallet.address, listingInfo.price);
    await mintTx.wait()

    console.log("Mint tx hash:", mintTx.hash);

    const approveTx = await packCoin.approve(packMarketAddress, listingInfo.price);
    await approveTx.wait()

    console.log("Approve tx hash:", approveTx.hash);
  }

  const buyTx = await packMarket.buy(
    listingInfo.owner, 
    listingInfo.tokenId, 
    1, 
    {
      gasLimit: 2000000,
      value: listingInfo.currency != packCoinAddress ? listingInfo.price : 0
    }
  );
  await buyTx.wait()

  console.log("Buy tx hash: ", buyTx.hash);

  const openTx = await packToken.openPack(listingInfo.tokenId);
  await openTx.wait()

  console.log("Open pack tx: ", openTx.hash);
}

main(targetTokenId)
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });