import { BigNumber } from "ethers";
import { ethers } from "hardhat";

export function getURIs(num: number = 0): string[] {
  const numToReturn = num == 0 ? 5 + Math.floor(Math.random() * 5) : num;

  const step = 1 + Math.floor(Math.random() * 100);
  const masterURI: string = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
  return [...Array(numToReturn).keys()].map((val: number) => masterURI + (val + step).toString());
}

export function getAmounts(num: number): number[] {
  return [...Array(num).keys()].map(val => 1 + Math.floor(Math.random() * 100));
}

export function getAmountBounded(max: number): BigNumber {
  const amount = Math.floor(Math.random() * max);
  return amount == 0 ? BigNumber.from(max) : BigNumber.from(amount);
}

export function getBoundedEtherAmount(): BigNumber {
  return ethers.utils.parseEther((1 + Math.random()).toString());
}
