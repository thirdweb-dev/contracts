import hre, { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "@ethersproject/contracts";

import addresses from "../../utils/address.json";
import fetch from 'node-fetch';

const { signMetaTxRequest } = require("../../utils/signer.js");

import dotenv from "dotenv";
import { Wallet } from "@ethersproject/wallet";
dotenv.config();

// Transaction parameters.
const packId: number = 1;
const encodedPackId = ethers.utils.defaultAbiCoder.encode(["uint256"], [packId]).slice(2);

async function main() {
  
  // Get signers
  const [packOwner]: SignerWithAddress[] = await ethers.getSigners();

  // Get chain ID
  const chainID: number = await packOwner.getChainId();

  console.log(`Performing tx with account: ${await packOwner.getAddress()} in chain: ${chainID}`);

  // Get `Pack.sol` and `Forwarder.sol` contracts
  const networkName: string = hre.network.name;
  const { pack: packAddress, forwarder: forwarderAddress } = addresses[networkName as keyof typeof addresses];
  const pack: Contract = await ethers.getContractAt("Pack", packAddress);
  const forwarder: Contract = await ethers.getContractAt("Forwarder", forwarderAddress);

  // Display pack creator's pack balance
  let packBalance = await pack.balanceOf(packOwner.address, packId);
  console.log("Pack balance before: ", parseInt(packBalance.toString()), "Pack ID: ", packId);

  // Send each account a pack.
  const generatedSigners: Wallet[] = [];

  for(let i = 0; i < 10; i += 1) {
    const newWallet: Wallet = ethers.Wallet.createRandom();
    generatedSigners.push(newWallet);

    const sendTx = await pack.connect(packOwner).safeTransferFrom(
      packOwner.address, newWallet.address, packId, 1, ethers.utils.toUtf8Bytes("")
    )

    console.log(`Sending packs to ${newWallet.address} at ${sendTx.hash}`);

    await sendTx.wait();
  }

  console.log("\n All packs sent \n");

  // =====  Meta tx setup  =====

  let alchemyKey: string = process.env.ALCHEMY_KEY || "";
  const providerURL = `https://polygon-${networkName}.g.alchemy.com/v2/${alchemyKey}`
  const provider = new ethers.providers.JsonRpcProvider(providerURL)

  const blocks: number[] = []

  await Promise.all(generatedSigners.map(async (signer) => { 

    // Get payload parameters
    const from = signer.address;
    const to = pack.address;
    const data = pack.interface.encodeFunctionData("openPack", [encodedPackId]);

    // Get signed transaction data
    let txRequest = await signMetaTxRequest(signer.privateKey, forwarder, { from, to, data });

    const response = await (fetch as any)(process.env.OZ_AUTOTASK_URL, {
      method: "POST",
      body: JSON.stringify(txRequest),
      headers: { "Content-Type": "application/json" },
      mode: "no-cors",
    })

    const parsedResponse = await response.json();
    const parsedResult = JSON.parse(parsedResponse.result);

    const txBlockNumber: number | undefined = (await provider.getTransaction(parsedResult.txHash)).blockNumber;
    blocks.push((txBlockNumber as number));

    console.log(`Pack opened by ${signer.address} at block ${txBlockNumber} and hash ${parsedResult.txHash}`);
  }));

  // Display max block difference
  console.log(`Block difference: ${Math.max(...blocks) - Math.min(...blocks)}`);

  // Display pack creator's pack balance
  packBalance = await pack.balanceOf(packOwner.address, packId);
  console.log("Pack balance before: ", parseInt(packBalance.toString()), "Pack ID: ", packId);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
