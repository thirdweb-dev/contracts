import { ethers } from "ethers"

export const chainlinkVarsRinkeby = {
  vrfCoordinator: '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
  linkTokenAddress: '0x01be23585060835e02b77ef475b0cc51aa1e0709',
  keyHash: '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311',
  fees: ethers.utils.parseEther("0.1")
}