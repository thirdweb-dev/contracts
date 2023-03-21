// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import "@openzeppelin/contracts/utils/Address.sol";

interface IDeployer {
    struct Transaction {
        address predictedAddress;
        address to;
        bytes data;
    }
}

contract Deployer is IDeployer {
    /// @dev Deploys a proxy that points to the given implementation.
    constructor(Transaction[] memory transactions) payable {
        uint256 len = transactions.length;
        for (uint256 i = 0; i < len; i++) {
            if (transactions[i].predictedAddress.code.length == 0) {
                transactions[i].to.call(transactions[i].data);
            }
        }
    }
}
