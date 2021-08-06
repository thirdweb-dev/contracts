import { ethers } from "ethers"

export const chainlinkVarsMatic = {
    vrfCoordinator: '0x3d2341ADb2D31f1c5530cDC622016af293177AE0',
    linkTokenAddress: '0xb0897686c545045aFc77CF20eC7A532E3120E0F1',
    keyHash: '0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da',
    fees: ethers.utils.parseEther("0.0001")
}

export const chainlinkVarsMumbai = {
    vrfCoordinator: '0x8C7382F9D8f56b33781fE506E897a4F1e2d17255',
    linkTokenAddress: '0x326C977E6efc84E512bB9C30f76E30c160eD06FB',
    keyHash: '0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4',
    fees: ethers.utils.parseEther("0.0001")
}