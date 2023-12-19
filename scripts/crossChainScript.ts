// import { ethers } from "ethers";

// const provider = new ethers.providers.JsonRpcProvider("<YOUR_RPC_PROVIDER_URL>");
// const privateKey = "<YOUR_PRIVATE_KEY>";

// const crossChainTokenTransferAddress = "<YOUR_CONTRACT_ADDRESS>";
// const crossChainTokenTransferAbi = require("./CrossChainTokenTransfer.json").abi;
// const crossChainTokenTransferMasterAddress = "<YOUR_CONTRACT_ADDRESS>";
// const crossChainTokenTransferMasterAbi = require("./CrossChainTokenTransfer.json").abi;
// const wallet = new ethers.Wallet(privateKey, provider);
// let estimate = 0;

// async function estimateFee() {
//   const contract = new ethers.Contract(crossChainTokenTransferAddress, crossChainTokenTransferAbi, wallet);

//   // Replace these values with the actual parameters
//   const destinationChainSelector = 123; // Example value
//   const receiver = "0x1234567890123456789012345678901234567890"; // Example value
//   const token = "0x9876543210987654321098765432109876543210"; // Example value
//   const amount = ethers.utils.parseEther("10"); // Example value in ether

//   try {
//     // Call the estimateFee function
//     estimate = await contract.estimateFee(destinationChainSelector, receiver, token, amount);

//     console.log("Estimated Fee:", estimate.toString());
//   } catch (error) {
//     // @ts-ignore
//     console.error("Error estimating fee:", error.message);
//   }
// }

// estimateFee();

// async function allowlistDestinationChain(destinationChainSelector: number, allowed: boolean) {
//   const contract = new ethers.Contract(crossChainTokenTransferAddress, crossChainTokenTransferAbi, wallet);

//   try {
//     // Call the allowlistDestinationChain function
//     const transaction = await contract.allowlistDestinationChain(destinationChainSelector, allowed);
//     await transaction.wait();

//     console.log("allowlistDestinationChain transaction successful!");
//   } catch (error) {
//     //@ts-ignore
//     console.error("Error calling allowlistDestinationChain:", error.message);
//   }
// }

// async function signMessage(message: string) {
//   // Sign the message
//   const signature = await wallet.signMessage(message);

//   console.log("Message:", message);
//   console.log("Signature:", signature);

//   return [message, signature];
// }

// async function proceed(messageHash: string, signature: string) {
//   const contract = new ethers.Contract(crossChainTokenTransferAddress, crossChainTokenTransferAbi, wallet);

//   try {
//     // Call the _proceed function
//     const transaction = await contract._proceed(messageHash, signature);
//     await transaction.wait();

//     console.log("_proceed transaction successful!");
//   } catch (error) {
//     //@ts-ignore
//     console.error("Error calling _proceed:", error.message);
//   }
// }

// async function initiateTokenTransferWithLink(
//   estimate: string,
//   _smartWalletAccount: string,
//   _ccip: string,
//   _link: string,
//   _token: string,
//   _destinationChainSelector: string,
//   _receiver: string,
//   _tokenAmount: string,
// ) {
//   const contract = new ethers.Contract(crossChainTokenTransferMasterAddress, crossChainTokenTransferMasterAbi, wallet);

//   try {
//     // initiate transaction with Link token
//     await contract._initiateTokenTransferWithLink(
//       _smartWalletAccount,
//       _ccip,
//       _link,
//       _token,
//       _destinationChainSelector,
//       _receiver,
//       _tokenAmount,
//       estimate,
//     );

//     // Listen for the HashGenerated event
//     const filter = contract.filters.HashGenerated(_smartWalletAccount, null);
//     const events = await contract.queryFilter(filter);

//     events.forEach(event => {
//       //@ts-ignore
//       console.log("HashGenerated Event - Owner:", event.args.owner, "Hash:", event.args.hash);
//     });
//   } catch (error) {
//     //@ts-ignore
//     console.error("Error estimating fee:", error.message);
//   }
// }

// async function initiateTokenTransferWithNativeToken(
//   _smartWalletAccount: string,
//   _ccip: string,
//   _token: string,
//   _destinationChainSelector: string,
//   _receiver: string,
//   _tokenAmount: string,
//   _estimate: string,
// ) {
//   const contract = new ethers.Contract(crossChainTokenTransferMasterAddress, crossChainTokenTransferMasterAbi, wallet);

//   try {
//     // initiate transaction with Native token
//     await contract._initiateTokenTransferWithNativeToken(
//       _smartWalletAccount,
//       _ccip,
//       _token,
//       _destinationChainSelector,
//       _receiver,
//       _tokenAmount,
//       _estimate,
//     );

//     // Listen for the HashGenerated event
//     const filter = contract.filters.HashGenerated(_smartWalletAccount, null);
//     const events = await contract.queryFilter(filter);

//     events.forEach(event => {
//       //@ts-ignore
//       console.log("HashGenerated Event - Owner:", event.args.owner, "Hash:", event.args.hash);
//     });
//   } catch (error) {
//     //@ts-ignore
//     console.error("Error estimating fee:", error.message);
//   }
// }
