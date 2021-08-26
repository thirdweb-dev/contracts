import { ethers } from "hardhat";
import ProtocolControlABI from "../abi/ProtocolControl.json";

/// NOTE: set the right netowrk.
const ERC20ABI = [
  {
    constant: true,
    inputs: [
      {
        name: "_owner",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        name: "balance",
        type: "uint256",
      },
    ],
    payable: false,
    type: "function",
  },
];

async function main() {
  const [funder] = await ethers.getSigners();
  const protocolCenterAddress = "0x429ACf993C992b322668122a5fC5593200493ea8";
  const usdcAddress = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174";
  const treasuryAddress = "0xd451D7C340f84a0B57b0923C1bD931F6447c75A6";
  const usdcContract = await ethers.getContractAt(ERC20ABI, usdcAddress);
  const protocolContract = await ethers.getContractAt(ProtocolControlABI, protocolCenterAddress);
  const balance = await usdcContract.balanceOf(usdcAddress);
  const tx = await protocolContract.transferProtocolFunds(usdcAddress, treasuryAddress, balance);
  await tx.wait();
  console.log("Transferring", balance.toString(), "to", treasuryAddress);
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
