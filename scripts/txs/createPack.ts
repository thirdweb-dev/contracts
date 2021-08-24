import { ethers } from 'hardhat';
import { Contract, BigNumber } from 'ethers';

import { addresses } from '../../utils/contracts';

/// NOTE: set the right network you want.

// Transaction parameters.
const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
const rewardURIs: string[] = [
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3"
]
const rewardSupplies: number[] = [5, 10, 20];
const openStartAndEnd: number = 0;

async function createPack(
  packURI: string,
  rewardURIs: string[],
  rewardSupplies: number[],

  openStart: number,
  openEnd: number
) {

  // const manualGasPrice: BigNumber = ethers.utils.parseUnits("5", "gwei");

  // Get signer.
  const [caller] = await ethers.getSigners();

  // Get contract instances connected to wallet.
  const { rinkeby: { pack, rewards } } = addresses;
  const packContract: Contract = await ethers.getContractAt("Pack", pack)
  const rewardsContract: Contract = await ethers.getContractAt("Rewards", rewards)

  // Create packs with rewards and list packs for sale.
  const createPackTx = await rewardsContract.connect(caller).createPackAtomic(
    rewardURIs,
    rewardSupplies,
    packURI,
    openStart,
    openEnd
  )
  console.log("Create pack: ", createPackTx.hash);
  const receipt = await createPackTx.wait();

  const topic = packContract.interface.getEventTopic("PackCreated")
  const log = receipt.logs.find((x: any) => x.topics.indexOf(topic) >= 0);
  const packCreatedEvent: any = packContract.interface.parseLog(log);

  console.log(packCreatedEvent)

  const packId = packCreatedEvent.args.packState.packId
  console.log(packId)
}

createPack(
  packURI,
  rewardURIs,
  rewardSupplies,
  openStartAndEnd,
  openStartAndEnd
).then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })