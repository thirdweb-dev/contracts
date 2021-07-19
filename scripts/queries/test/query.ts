import { JsonRpcProvider } from "@ethersproject/providers";
import { Contract, ethers, EventFilter } from "ethers";

// Get ABI, address and provider.
import packABI from "./Pack.json";
const packAddress: string = "0x6416795AF11336ef33EF7BAd1354F370141f8728"
const provider: JsonRpcProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, 
  "rinkeby"
);

import dotenv from 'dotenv'
dotenv.config();

async function main() {

  // Get contract instance.
  const pack: Contract = new ethers.Contract(packAddress, packABI, provider);

  // Get value by which you want to filter.
  const creator = "0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372";

  // Event:  event PackCreated(address indexed creator, uint indexed tokenId, string tokenUri, uint maxSupply);
  // You can filter event logs by indexed values -- in this case, `creator` and `tokenId`.

  // Create filter.
  const packFilter: EventFilter = pack.filters.PackCreated(creator);
  // Define range of blocks to search from - this is important for speed.
  const fromBlock: number = 8704840; // Contract created at this block.
  const toBlock: number = 8754391; // The last transaction made. You can get current block number from provider -- await provider.getBlockNumber().

  // An array with the objects i.e. events that match the filter.
  const queryResult = await pack.queryFilter(packFilter, fromBlock, toBlock); 

  console.log(queryResult);

  // An array of the args of events that match the filter.
  const eventArgs = queryResult.map(matchedEvent => matchedEvent.args);
  console.log(eventArgs)

  // An array of one of the args, here `creator`, of the events that match the filter.
  const creators = eventArgs.map(matchedArgs => {
    if (matchedArgs) return matchedArgs.creator;
  });
  console.log(creators)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  });
