// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "./../utils/BaseAccount.sol";

// Fixed Extensions
import "../../extension/Multicall.sol";
import "../../dynamic-contracts/extension/Initializable.sol";
import "../../eip/ERC1271.sol";

// Utils
import "../../openzeppelin-presets/utils/cryptography/ECDSA.sol";
import "../../dynamic-contracts/extension/PermissionsEnumerable.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract AccountCore is Initializable, Multicall, BaseAccount, ERC1271 {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /// @notice EIP 4337 Entrypoint contract.
    IEntryPoint private immutable entrypointContract;

    /*///////////////////////////////////////////////////////////////
                    Constructor, Initializer, Modifiers
    //////////////////////////////////////////////////////////////*/

    // solhint-disable-next-line no-empty-blocks
    receive() external payable virtual {}

    constructor(IEntryPoint _entrypoint) {
        entrypointContract = _entrypoint;
    }

    /// @notice Initializes the smart contract wallet.
    function initialize(address _defaultAdmin, bytes calldata) public virtual initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the EIP 4337 entrypoint contract.
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return entrypointContract;
    }

    /// @notice Returns the balance of the account in Entrypoint.
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /// @notice Returns whether a signer is authorized to perform transactions using the wallet.
    function isValidSigner(address _signer) public view virtual returns (bool) {
        return _hasRole(SIGNER_ROLE, _signer) || _hasRole(DEFAULT_ADMIN_ROLE, _signer);
    }

    /// @notice See EIP-1271
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        virtual
        override
        returns (bytes4 magicValue)
    {
        address signer = _hash.recover(_signature);
        if (isValidSigner(signer)) {
            magicValue = MAGICVALUE;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit funds for this account in Entrypoint.
    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    /// @notice Withdraw funds for this account from Entrypoint.
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public {
        require(_hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Account: not admin");
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates the signature of a user operation.
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);

        if (!isValidSigner(signer)) return SIG_VALIDATION_FAILED;
        return 0;
    }

    /// @notice See Permissions-hasRole
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[_role][_account];
    }

    /// @notice See Permissions-RoleGranted
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /// @notice See Permissions-setupRole
    function _setupRole(bytes32 role, address account) internal virtual {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        data._hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }
}
