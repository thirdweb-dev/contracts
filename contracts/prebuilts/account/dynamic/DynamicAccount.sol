// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "../utils/AccountCore.sol";

import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouter.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract DynamicAccount is AccountCore, BaseRouter {
    /*///////////////////////////////////////////////////////////////
                    Constructor and Initializer
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint, Extension[] memory _defaultExtensions)
        AccountCore(_entrypoint, msg.sender)
        BaseRouter(_defaultExtensions)
    {
        _disableInitializers();
    }

    /// @notice Initializes the smart contract wallet.
    function initialize(address _defaultAdmin, bytes calldata) public override initializer {
        __BaseRouter_init();
        AccountCoreStorage.data().firstAdmin = _defaultAdmin;
        _setAdmin(_defaultAdmin, true);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return isAdmin(msg.sender);
    }
}
