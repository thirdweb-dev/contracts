// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// ========== Interface ==========
import "./interface/IAccount.sol";

// ========== Utils ==========
import "../extension/Multicall.sol";
import "../extension/PermissionsEnumerable.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 *  Basic actions:
 *      - Deploy smart contracts
 *      - Make transactions on contracts
 *      - Sign messages
 *      - Own assets
 */
contract Account is IAccount, EIP712, Multicall, PermissionsEnumerable {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER");

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256(
            "TransactionParams(address signer,address target,bytes data,uint256 nonce,uint256 value,uint256 gas,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    bytes32 private constant DEPLOY_TYPEHASH =
        keccak256(
            "DeployParams(address signer,bytes bytecode,bytes32 salt,uint256 value,uint256 nonce,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The admin of the wallet; the only address that is a valid `msg.sender` in this contract.
    address public controller;

    /// @notice The nonce of the wallet.
    uint256 public nonce;

    /*///////////////////////////////////////////////////////////////
                        Constructor & Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor(address _controller, address _signer) payable EIP712("thirdwebWallet", "1") {
        controller = _controller;
        _setupRole(SIGNER_ROLE, _signer);

        emit SignerAdded(_signer);
    }

    /// @dev Checks whether the caller is `controller`.
    modifier onlyController() {
        require(controller == msg.sender, "Account: caller not controller.");
        _;
    }

    /// @dev Checks whether the caller is self.
    modifier onlySelf() {
        require(controller == msg.sender, "Account: caller not self.");
        _;
    }

    /// @dev Ensures conditions for a valid wallet action: a call or deployment.
    modifier onlyValidWalletCall(
        uint256 _nonce,
        uint256 _value,
        uint128 _validityStartTimestamp,
        uint128 _validityEndTimestamp
    ) {
        require(msg.value == _value, "Account: incorrect value sent.");
        require(
            _validityStartTimestamp <= block.timestamp && block.timestamp < _validityEndTimestamp,
            "Account: request premature or expired."
        );
        require(_nonce == nonce, "Account: incorrect nonce.");
        nonce += 1;
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Lets this contract receive native tokens.
    receive() external payable {}

    /// @notice Perform transactions; send native tokens or call a smart contract.
    function execute(TransactionParams calldata _params, bytes calldata _signature)
        external
        payable
        onlyController
        onlyValidWalletCall(_params.nonce, _params.value, _params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (bool success)
    {
        bytes32 messageHash = keccak256(
            abi.encode(
                EXECUTE_TYPEHASH,
                _params.signer,
                _params.target,
                keccak256(_params.data),
                _params.nonce,
                _params.value,
                _params.gas,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        _validateSignature(_params.signer, messageHash, _signature);
        success = _call(_params);

        emit TransactionExecuted(
            _params.signer,
            _params.target,
            _params.data,
            _params.nonce,
            _params.value,
            _params.gas
        );
    }

    /// @notice Deploys a smart contract.
    function deploy(DeployParams calldata _params, bytes calldata _signature)
        external
        payable
        onlyController
        onlyValidWalletCall(_params.nonce, _params.value, _params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (address deployment)
    {
        bytes32 messageHash = keccak256(
            abi.encode(
                DEPLOY_TYPEHASH,
                _params.signer,
                keccak256(bytes(_params.bytecode)),
                _params.salt,
                _params.value,
                _params.nonce,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        _validateSignature(_params.signer, messageHash, _signature);
        deployment = Create2.deploy(_params.value, _params.salt, _params.bytecode);
        emit ContractDeployed(deployment);
    }

    /// @notice Adds a signer to this contract.
    function addSigner(address _signer) external onlySelf returns (bool success) {
        grantRole(SIGNER_ROLE, _signer);
        success = true;

        emit SignerAdded(_signer);
    }

    /// @notice Updates the signer of this contract.
    function removeSigner(address _signer) external onlySelf returns (bool success) {
        revokeRole(SIGNER_ROLE, _signer);
        success = true;

        emit SignerRemoved(_signer);
    }

    /// @notice See EIP-1271. Returns whether a signature is a valid signature made on behalf of this contract.
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view override returns (bytes4) {
        address signer = _hash.recover(_signature);

        // Validate signatures
        if (hasRole(SIGNER_ROLE, signer)) {
            return MAGICVALUE;
        } else {
            return 0xffffffff;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Validates a signature.
    function _validateSignature(
        address _signer,
        bytes32 _messageHash,
        bytes calldata _signature
    ) internal view {
        bool validSignature = false;

        if (_signer.code.length > 0) {
            validSignature = MAGICVALUE == IERC1271(_signer).isValidSignature(_messageHash, _signature);
        } else {
            address recoveredSigner = _hashTypedDataV4(_messageHash).recover(_signature);
            validSignature = _signer == recoveredSigner && hasRole(SIGNER_ROLE, _signer);
        }

        require(validSignature, "Account: invalid signer.");
    }

    /// @dev Performs a call; sends native tokens or calls a smart contract.
    function _call(TransactionParams memory txParams) internal returns (bool) {
        address target = txParams.target;

        bool success;
        bytes memory result;
        if (txParams.gas > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = target.call{ gas: txParams.gas, value: txParams.value }(txParams.data);
        } else {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = target.call{ value: txParams.value }(txParams.data);
        }
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return success;
    }
}
