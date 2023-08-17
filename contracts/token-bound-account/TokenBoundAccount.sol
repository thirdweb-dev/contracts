// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "../smart-wallet/utils/BaseAccount.sol";

// Extensions
import "../extension/Multicall.sol";
import "../dynamic-contracts/extension/Initializable.sol";
import "../dynamic-contracts/extension/ContractMetadata.sol";
import "../openzeppelin-presets/token/ERC721/utils/ERC721Holder.sol";
import "../openzeppelin-presets/token/ERC1155/utils/ERC1155Holder.sol";
import "../eip/ERC1271.sol";

// Utils
import "../openzeppelin-presets/utils/cryptography/ECDSA.sol";
import "../smart-wallet/utils/BaseAccountFactory.sol";

import "./erc6551-utils/ERC6551AccountLib.sol";
import "./erc6551-utils/IERC6551Account.sol";

import "../eip/interface/IERC721.sol";
import "../openzeppelin-presets/utils/cryptography/EIP712.sol";

contract TokenBoundAccount is
    Initializable,
    ERC1271,
    Multicall,
    BaseAccount,
    ContractMetadata,
    ERC721Holder,
    ERC1155Holder,
    IERC6551Account,
    EIP712
{
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event TokenBoundAccountCreated(address indexed account, bytes indexed data);

    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP 4337 factory for this contract.
    address public immutable factory;

    /// @notice EIP 4337 Entrypoint contract.
    IEntryPoint private immutable entrypointContract;

    /*///////////////////////////////////////////////////////////////
                    Constructor, Initializer, Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Executes once when a contract is created to initialize state variables
     *
     * @param _entrypoint - 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
     * @param _factory - The factory contract address to issue token Bound accounts
     *
     */
    constructor(IEntryPoint _entrypoint, address _factory) EIP712("TokenBoundAccount", "1") {
        _disableInitializers();
        factory = _factory;
        entrypointContract = _entrypoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable virtual {}

    /// @notice Initializes the smart contract wallet.
    function initialize(address _defaultAdmin, bytes calldata _data) public virtual initializer {
        emit TokenBoundAccountCreated(_defaultAdmin, _data);
    }

    /// @notice Returns whether a signer is authorized to perform transactions using the wallet.
    function isValidSigner(address _signer, UserOperation calldata) public view returns (bool) {
        return (owner() == _signer);
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

        if (owner() == signer) {
            magicValue = MAGICVALUE;
        }
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();

        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyAdminOrEntrypoint returns (bytes memory result) {
        return _call(to, value, data);
    }

    /// @notice Withdraw funds for this account from Entrypoint.
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public virtual {
        require(owner() == msg.sender, "Account: not NFT owner");
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function token()
        external
        view
        returns (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        )
    {
        return ERC6551AccountLib.token();
    }

    function nonce() external view returns (uint256) {
        return getNonce();
    }

    /// @notice See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns the EIP 4337 entrypoint contract.
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return entrypointContract;
    }

    /// @notice Returns the balance of the account in Entrypoint.
    function getDeposit() public view virtual returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /// @notice Executes a transaction (called directly from an admin, or by entryPoint)
    function execute(
        address _target,
        uint256 _value,
        bytes calldata _calldata
    ) external virtual onlyAdminOrEntrypoint {
        _call(_target, _value, _calldata);
    }

    /// @notice Executes a sequence transaction (called directly from an admin, or by entryPoint)
    function executeBatch(
        address[] calldata _target,
        uint256[] calldata _value,
        bytes[] calldata _calldata
    ) external virtual onlyAdminOrEntrypoint {
        require(_target.length == _calldata.length && _target.length == _value.length, "Account: wrong array lengths.");
        for (uint256 i = 0; i < _target.length; i++) {
            _call(_target[i], _value[i], _calldata[i]);
        }
    }

    /// @notice Deposit funds for this account in Entrypoint.
    function addDeposit() public payable virtual {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _call(
        address _target,
        uint256 value,
        bytes memory _calldata
    ) internal virtual returns (bytes memory result) {
        bool success;
        (success, result) = _target.call{ value: value }(_calldata);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @notice Validates the signature of a user operation.
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);

        if (!isValidSigner(signer, userOp)) return SIG_VALIDATION_FAILED;
        return 0;
    }

    function getFunctionSignature(bytes calldata data) internal pure returns (bytes4 functionSelector) {
        require(data.length >= 4, "Data too short");
        return bytes4(data[:4]);
    }

    function decodeExecuteCalldata(bytes calldata data) internal pure returns (address _target, uint256 _value) {
        require(data.length >= 4 + 32 + 32, "Data too short");

        // Decode the address, which is bytes 4 to 35
        _target = abi.decode(data[4:36], (address));

        // Decode the value, which is bytes 36 to 68
        _value = abi.decode(data[36:68], (uint256));
    }

    function decodeExecuteBatchCalldata(bytes calldata data)
        internal
        pure
        returns (
            address[] memory _targets,
            uint256[] memory _values,
            bytes[] memory _callData
        )
    {
        require(data.length >= 4 + 32 + 32 + 32, "Data too short");

        (_targets, _values, _callData) = abi.decode(data[4:], (address[], uint256[], bytes[]));
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdminOrEntrypoint() {
        require(msg.sender == address(entryPoint()) || msg.sender == owner(), "Account: not admin or EntryPoint.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Account: not admin.");
        _;
    }
}
