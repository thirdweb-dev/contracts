require('dotenv').config();
const { ethers } = require("ethers");

// Get contract ABIs
const packTokenABI = require('../../abi/Pack.json')
const packMarketABI = require('../../abi/PackMarket.json');

// Set up wallet.
const privateKey = process.env.TEST_PRIVATE_KEY_SECONDARY;
const alchemyEndpoint = process.env.ALCHEMY_ENDPOINT;

const provider = new ethers.providers.JsonRpcProvider(alchemyEndpoint, 'rinkeby');
const wallet = new ethers.Wallet(privateKey, provider)

// Set up contracts
const packTokenAddress = '0xcE41C2D82A91d3E7C63C26522eD30Ab50f3de7A1'
const packMarketAddress = '0x27666861b25D830526283D0499c5A428696c58D2'

const packToken = new ethers.Contract(packTokenAddress, packTokenABI, wallet);
const packMarket = new ethers.Contract(packMarketAddress, packMarketABI, wallet);

let targetTokenId = 0;

async function main(tokenId) {
  const listingInfo = await packMarket.listings(
    '0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372',
    tokenId
  )

  const buyTx = await packMarket.buy(
    listingInfo.owner, 
    listingInfo.tokenId, 
    1, 
    {
      gasLimit: 2000000,
      value: listingInfo.price
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