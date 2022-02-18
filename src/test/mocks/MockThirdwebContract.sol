// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "contracts/interfaces/IThirdwebContract.sol";

contract MockThirdwebContract is IThirdwebContract {
    string public contractURI;
    bytes32 public constant contractType = bytes32("MOCK");
    uint8 public constant contractVersion = 1;

    function setContractURI(string calldata _uri) external {
        contractURI = _uri;
    }
}
