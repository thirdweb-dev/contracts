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

interface IThrowawaySplit {
    struct Deployer {
        address deployer;
        uint256 value;
    }
}

contract ThrowawaySplit is IThrowawaySplit {
    /// @dev Deploys a proxy that points to the given implementation.
    constructor(Deployer[] memory deployers) payable {
        uint256 len = deployers.length;
        for (uint256 i = 0; i < len; i++) {
            if (deployers[i].deployer.balance == 0) {
                deployers[i].deployer.call{ value: deployers[i].value }("");
            }
        }
    }
}
