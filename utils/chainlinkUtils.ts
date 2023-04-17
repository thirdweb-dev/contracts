import { ethers } from "ethers";

export const chainlinkVars = {
  "137": {
    vrfV2Wrapper: "0x4e42f0adEB69203ef7AaA4B7c414e5b1331c14dc",
    vrfCoordinator: "0x3d2341ADb2D31f1c5530cDC622016af293177AE0",
    linkTokenAddress: "0xb0897686c545045aFc77CF20eC7A532E3120E0F1",
    keyHash: "0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da",
    fees: ethers.utils.parseEther("0.0001"),
  },
  "80001": {
    vrfV2Wrapper: "0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693",
    vrfCoordinator: "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255",
    linkTokenAddress: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    keyHash: "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4",
    fees: ethers.utils.parseEther("0.0001"),
  },
  "1": {
    vrfV2Wrapper: "0x5A861794B927983406fCE1D062e00b9368d97Df6",
    vrfCoordinator: "0xf0d54349aDdcf704F77AE15b96510dEA15cb7952",
    linkTokenAddress: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
    keyHash: "0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445",
    fees: ethers.utils.parseEther("2"),
  },
};
