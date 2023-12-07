// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import "../utils/AccountCore.sol";
import "@thirdweb-dev/dynamic-contracts/src/core/Router.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IRouterState.sol";

contract ManagedAccount is AccountCore, Router, IRouterState {
    constructor(IEntryPoint _entrypoint, address _factory) AccountCore(_entrypoint, _factory) {}

    /// @notice Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        return Router(payable(factory)).getImplementationForFunction(_functionSelector);
    }

    /// @notice Returns all extensions of the Router.
    function getAllExtensions() external view returns (Extension[] memory) {
        return IRouterState(payable(factory)).getAllExtensions();
    }
}
