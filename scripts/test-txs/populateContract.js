require('dotenv').config();
const { ethers } = require("ethers");

// Get helper values
const { packURIs, rewardURIs, currencyAddresses } = require('./helperValues');

// Get contract ABIs
const packTokenABI = require('../../abi/Pack.json')
const packMarketABI = require('../../abi/PackMarket.json');

// Set up wallet.
const privateKey = process.env.TEST_PRIVATE_KEY;
const alchemyEndpoint = process.env.ALCHEMY_ENDPOINT;

const provider = new ethers.providers.JsonRpcProvider(alchemyEndpoint, 'rinkeby');
const wallet = new ethers.Wallet(privateKey, provider)

// Set up contracts
const packTokenAddress = '0x0c56B393043CDA7c726c27FdD64Bd9262428515F'
const packMarketAddress = '0x24574D0C177ad9E5cD74d9dBF5a9A729924e72e2'

const packToken = new ethers.Contract(packTokenAddress, packTokenABI, wallet);
const packMarket = new ethers.Contract(packMarketAddress, packMarketABI, wallet);

async function main() {

  await packToken.setApprovalForAll(packMarket.address, true);
  console.log("Approved market to handle tokens");
  
  let counter = 1;

  for(let packURI of packURIs.slice(1,2)) {
    let packID = parseInt((await packToken._currentTokenId()).toString());

    console.log(`Populating contracts - loop ${counter}`)
    
    // Create Pack
    const rewardMaxSupplies = []
    let maxPackSupply = 0;

    for(let i = 0; i < rewardURIs.length; i++) {
      let supply = Math.floor(Math.random() * 100);

      maxPackSupply += supply;
      rewardMaxSupplies.push(supply)
    }
    const createTx = await packToken.createPack(packURI, rewardMaxSupplies, rewardURIs, { gasLimit: 2000000 });
    await createTx.wait();
    console.log(`Created pack with ID ${packID}. Hash - ${createTx.hash}`)

    // List on market
    const price = parseFloat((`${Math.random()}`).slice(0,4));

    const currencyAddress = currencyAddresses[
      Math.floor(Math.random() * currencyAddresses.length)
    ]

    const listingTx = await packMarket.sell(packID, currencyAddress, price, maxPackSupply, { gasLimit: 2000000 });
    await listingTx.wait()
    console.log(`Listed pack ${packID} on the market. Hash - ${listingTx.hash}`)

    // END -- increment `packID`
    counter++;
  }

  console.log('SUCCESS')
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });