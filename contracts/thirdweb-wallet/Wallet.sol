// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// ========== Interface ==========
import "./interface/IWallet.sol";

// ========== Utils ==========
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 *  Basic actions:
 *      - Deploy smart contracts ✅
 *      - Make transactions on contracts ✅
 *      - Sign messages ✅
 *      - Own assets ✅
 */
contract Wallet is IWallet, EIP712 {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    bytes32 private constant EXECUTE_TYPEHASH =
        keccak256(
            "TransactionParams(address target,bytes data,uint256 nonce,uint256 txGas,uint256 value,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    bytes32 private constant DEPLOY_TYPEHASH =
        keccak256(
            "DeployParams(bytes bytecode,bytes32 salt,uint256 value,uint256 nonce,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The admin of the wallet; the only address that is a valid `msg.sender` in this contract.
    address public controller;

    /// @notice The signer of the wallet; a signature from this signer must be provided to execute with the wallet.
    address public signer;

    /// @notice The nonce of the wallet.
    uint256 public nonce;

    /*///////////////////////////////////////////////////////////////
                        Constructor & Modifiers
    //////////////////////////////////////////////////////////////*/

    constructor(address _controller, address _signer) payable EIP712("thirdwebWallet", "1") {
        controller = _controller;
        signer = _signer;
    }

    /// @dev Checks whether the caller is `controller`.
    modifier onlyController() {
        require(controller == msg.sender, "Wallet: caller not controller.");
        _;
    }

    /// @dev Ensures conditions for a valid wallet action: a call or deployment.
    modifier onlyValidWalletCall(
        uint256 _nonce,
        uint256 _value,
        uint128 _validityStartTimestamp,
        uint128 _validityEndTimestamp
    ) {
        require(msg.value == _value, "Wallet: incorrect value sent.");
        require(
            _validityStartTimestamp <= block.timestamp && block.timestamp < _validityEndTimestamp,
            "Wallet: request premature or expired."
        );
        require(_nonce == nonce, "Wallet: incorrect nonce.");
        nonce += 1;
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Lets this contract receive native tokens.
    receive() external payable {}

    /// @notice Perform transactions; send native tokens or call a smart contract.
    function execute(TransactionParams calldata _params, bytes memory _signature)
        external
        payable
        onlyController
        onlyValidWalletCall(_params.nonce, _params.value, _params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (bool success)
    {
        bytes32 messageHash = keccak256(
            abi.encode(
                EXECUTE_TYPEHASH,
                _params.target,
                keccak256(bytes(_params.data)),
                _params.nonce,
                _params.value,
                _params.gas,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        _validateSignature(messageHash, _signature);
        success = _call(_params);

        emit TransactionExecuted(signer, _params.target, _params.data, _params.nonce, _params.value, _params.gas);
    }

    /// @notice Deploys a smart contract.
    function deploy(DeployParams calldata _params, bytes memory _signature)
        external
        payable
        onlyController
        onlyValidWalletCall(_params.nonce, _params.value, _params.validityStartTimestamp, _params.validityEndTimestamp)
        returns (address deployment)
    {
        bytes32 messageHash = keccak256(
            abi.encode(
                DEPLOY_TYPEHASH,
                keccak256(bytes(_params.bytecode)),
                _params.salt,
                _params.value,
                _params.nonce,
                _params.validityStartTimestamp,
                _params.validityEndTimestamp
            )
        );
        _validateSignature(messageHash, _signature);
        deployment = Create2.deploy(_params.value, _params.salt, _params.bytecode);
        emit ContractDeployed(deployment);
    }

    /// @notice Updates the signer of this contract.
    function updateSigner(address _newSigner) external onlyController returns (bool success) {
        address prevSigner = signer;
        signer = _newSigner;
        success = true;

        emit SignerUpdated(prevSigner, _newSigner);
    }

    /// @notice See EIP-1271. Returns whether a signature is a valid signature made on behalf of this contract.
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view override returns (bytes4) {
        address signer_ = _hash.recover(_signature);

        // Validate signatures
        if (signer == signer_) {
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
    function _validateSignature(bytes32 _messageHash, bytes memory _signature) internal view {
        bool validSignature = false;
        address signer_ = signer;

        if (signer_.code.length > 0) {
            validSignature = MAGICVALUE == IERC1271(signer_).isValidSignature(_messageHash, _signature);
        } else {
            address recoveredSigner = _hashTypedDataV4(_messageHash).recover(_signature);
            validSignature = signer_ == recoveredSigner;
        }

        require(validSignature, "Wallet: invalid signer.");
    }

    /// @dev Performs a call; sends native tokens or calls a smart contract.
    function _call(TransactionParams memory txParams) internal returns (bool) {
        (bool success, bytes memory result) = txParams.target.call{ value: txParams.value, gas: txParams.gas }(
            txParams.data
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return success;
    }
}
