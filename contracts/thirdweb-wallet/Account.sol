// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

////////// Interface //////////
import "./interface/IAccount.sol";
import "./interface/IAccountAdmin.sol";

////////// Utils //////////
import "../extension/Multicall.sol";
import "../extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

////////// NOTE(S) //////////
/**
 *  - The Account can have many Signers.
 *  - There are two kinds of signers: `Admin`s and `Operator`s.
 *
 *    Each `Admin` can:
 *      - Perform any transaction / action on this account with 1/n approval.
 *      - Add signers or remove existing signers.
 *      - Approve a particular smart contract call (i.e. fn signature + contract address) for an `Operator`.
 *
 *    Each `Operator` can:
 *      - Perform smart contract calls it is approved for (i.e. wherever Operator => (fn signature + contract address) => TRUE).
 *
 *  - The Account can:
 *      - Deploy smart contracts.
 *      - Send native tokens.
 *      - Call smart contracts.
 *      - Sign messages. (EIP-1271)
 *      - Own and transfer assets. (ERC-20/721/1155)
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

    bytes32 private constant SIGNER_UPDATE_TYPEHASH =
        keccak256(
            "SignerUpdateParams(address signer,bytes32 credentials,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The admin smart contract of the account.
    address public controller;

    /// @notice The nonce of the account.
    uint256 public nonce;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _controller, address _signer) payable EIP712("thirdwebWallet", "1") {
        controller = _controller;
        _setupRole(DEFAULT_ADMIN_ROLE, _signer);

        emit SignerAdded(_signer);
    }

    /*///////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether the caller is `controller`.
    modifier onlyController() {
        require(controller == msg.sender, "Account: caller not controller.");
        _;
    }

    /// @dev Checks whether the caller is self.
    modifier onlySelf() {
        require(msg.sender == address(this), "Account: caller not self.");
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
                        Receive native tokens.
    //////////////////////////////////////////////////////////////*/

    /// @notice Lets this contract receive native tokens.
    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
     Execute a transaction. Send native tokens, call smart contracts
    //////////////////////////////////////////////////////////////*/

    /// @notice Perform transactions; send native tokens or call a smart contract.
    function execute(TransactionParams calldata _params, bytes calldata _signature)
        external
        payable
        onlyController
        onlyValidWalletCall(_params.nonce, _params.value, _params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (bool success)
    {
        {
            bytes32 messageHash = keccak256(_encodeTransactionParams(_params));
            _validateSignature(_params.signer, messageHash, _signature);
        }
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

    /*///////////////////////////////////////////////////////////////
                        Deploy smart contracts.
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a smart contract.
    function deploy(DeployParams calldata _params, bytes calldata _signature)
        external
        payable
        onlyController
        onlyValidWalletCall(_params.nonce, _params.value, _params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (address deployment)
    {
        {
            bytes32 messageHash = keccak256(_encodeDeployParams(_params));
            _validateSignature(_params.signer, messageHash, _signature);
        }
        deployment = Create2.deploy(_params.value, _params.salt, _params.bytecode);
        emit ContractDeployed(deployment);
    }

    /*///////////////////////////////////////////////////////////////
                Change signer composition to the account.
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a signer to the account.
    function addSigner(SignerUpdateParams calldata _params, bytes calldata _signature) external onlySelf {
        bytes32 messageHash = keccak256(
            abi.encode(
                SIGNER_UPDATE_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        _validateSignature(_params.signer, messageHash, _signature);

        _setupRole(SIGNER_ROLE, _params.signer);

        emit SignerAdded(_params.signer);

        IAccountAdmin(controller).addSignerToAccount(_params.signer, _params.credentials);
    }

    /// @notice Removes a signer to the account.
    function removeSigner(SignerUpdateParams calldata _params, bytes calldata _signature) external onlySelf {
        bytes32 messageHash = keccak256(
            abi.encode(
                SIGNER_UPDATE_TYPEHASH,
                _params.signer,
                _params.credentials,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        _validateSignature(_params.signer, messageHash, _signature);

        _revokeRole(SIGNER_ROLE, _params.signer);

        emit SignerRemoved(_params.signer);

        IAccountAdmin(controller).removeSignerToAccount(_params.signer, _params.credentials);
    }

    /*///////////////////////////////////////////////////////////////
                    EIP-1271 Smart contract signatures
    //////////////////////////////////////////////////////////////*/

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

    /*///////////////////////////////////////////////////////////////
                    Receive assets (ERC-721/1155)
    //////////////////////////////////////////////////////////////*/

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

    function _encodeTransactionParams(TransactionParams calldata _params) private pure returns (bytes memory) {
        return
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
            );
    }

    function _encodeDeployParams(DeployParams calldata _params) private pure returns (bytes memory) {
        return
            abi.encode(
                DEPLOY_TYPEHASH,
                _params.signer,
                keccak256(bytes(_params.bytecode)),
                _params.salt,
                _params.value,
                _params.nonce,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            );
    }
}
