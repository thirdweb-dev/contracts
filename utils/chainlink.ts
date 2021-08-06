import { ethers } from "ethers"

export const chainlinkVarsRinkeby = {
  vrfCoordinator: '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
  linkTokenAddress: '0x01be23585060835e02b77ef475b0cc51aa1e0709',
  keyHash: '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311',
  fees: ethers.utils.parseEther("0.1")
}

export const chainlinkVarsMainnet = {
  vrfCoordinator: '0xf0d54349aDdcf704F77AE15b96510dEA15cb7952',
  linkTokenAddress: '0x514910771AF9Ca656af840dff83E8264EcF986CA',
  keyHash: '0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445',
  fees: ethers.utils.parseEther("2")
}