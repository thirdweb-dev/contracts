// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./erc6551-utils/ERC6551AccountLib.sol";
import "./erc6551-utils/IERC6551Account.sol";

import "../eip/interface/IERC721.sol";
import "../smart-wallet/non-upgradeable/Account.sol";

contract TokenBoundAccount is Account, IERC6551Account {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event TokenBoundAccountCreated(address indexed account, bytes indexed data);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Executes once when a contract is created to initialize state variables
     *
     * @param _entrypoint - 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
     * @param _factory - The factory contract address to issue token Bound accounts
     *
     */
    constructor(IEntryPoint _entrypoint, address _factory) Account(_entrypoint, _factory) {
        _disableInitializers();
    }

    receive() external payable override(IERC6551Account, Account) {}

    /// @notice Returns whether a signer is authorized to perform transactions using the wallet.
    function isValidSigner(address _signer, UserOperation calldata) public view override returns (bool) {
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
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public virtual override {
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

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _call(
        address _target,
        uint256 value,
        bytes memory _calldata
    ) internal virtual override returns (bytes memory result) {
        bool success;
        (success, result) = _target.call{ value: value }(_calldata);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdminOrEntrypoint() override {
        require(msg.sender == address(entryPoint()) || msg.sender == owner(), "Account: not admin or EntryPoint.");
        _;
    }
}
