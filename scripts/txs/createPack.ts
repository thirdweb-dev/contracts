import { ethers } from 'hardhat';
import { Contract, BigNumber } from 'ethers';

import { addresses } from '../../utils/contracts';

/// NOTE: set the right network you want.

// Transaction parameters.
const rewardContract = addresses.mumbai.rewards;
const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
const rewardIds: number[] = [0,1,2]
const rewardSupplies: number[] = [5, 10, 20];
const openStartAndEnd: number = 0;

async function createPack(
  rewardContract: string,
  packURI: string,
  rewardIds: number[],
  rewardSupplies: number[],

  openStart: number,
  openEnd: number
) {

  const manualGasPrice: BigNumber = ethers.utils.parseUnits("5", "gwei");

  // Get signer.
  const [caller] = await ethers.getSigners();

  // Get contract instances connected to wallet.
  const { mumbai: { pack, rewards } } = addresses;
  const packContract: Contract = await ethers.getContractAt("Pack", pack)
  const rewardsContract: Contract = await ethers.getContractAt("Rewards", rewards)

  // Approve Handler to transfer reward tokens.
  const approveHandlerTx = await rewardsContract.connect(caller).setApprovalForAll(pack, true, { gasPrice: manualGasPrice});
  console.log("Approving Pack for reward tokens: ", approveHandlerTx.hash);
  await approveHandlerTx.wait()

  // Create packs with rewards and list packs for sale.
  const createPackTx = await packContract.connect(caller).createPack(
    packURI,
    rewardContract,
    rewardIds,
    rewardSupplies,
    openStart,
    openEnd,
    { gasPrice: manualGasPrice}
  );
  console.log("Create pack: ", createPackTx.hash);
  await createPackTx.wait();
}

createPack(
  rewardContract,
  packURI,
  rewardIds,
  rewardSupplies,
  openStartAndEnd,
  openStartAndEnd
).then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })