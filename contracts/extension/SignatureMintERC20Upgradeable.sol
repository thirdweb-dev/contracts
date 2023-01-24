// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/ISignatureMintERC20.sol";
import "./ERC1271Support.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

abstract contract SignatureMintERC20Upgradeable is
    Initializable,
    EIP712Upgradeable,
    ERC1271Support,
    ISignatureMintERC20
{
    using ECDSAUpgradeable for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256(
            "MintRequest(address signer,address to,address primarySaleRecipient,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

    function __SignatureMintERC20_init() internal onlyInitializing {
        __EIP712_init("SignatureMintERC20", "1");
    }

    function __SignatureMintERC20_init_unchained() internal onlyInitializing {}

    /// @dev Verifies that a mint request is signed by an account holding MINTER_ROLE (at the time of the function call).
    function verify(MintRequest calldata _req, bytes calldata _signature)
        public
        view
        override
        returns (bool success, address signer)
    {
        signer = _req.signer;
        bytes32 messageHash = keccak256(_encodeRequest(_req));
        _validateSignature(messageHash, _signature, signer);
        success = !minted[_req.uid] && _isAuthorizedSigner(signer);
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view virtual returns (bool);

    /// @dev Verifies a mint request and marks the request as minted.
    function _processRequest(MintRequest calldata _req, bytes calldata _signature) internal returns (address signer) {
        bool success;
        (success, signer) = verify(_req, _signature);

        require(success, "Invalid request");
        require(
            _req.validityStartTimestamp <= block.timestamp && block.timestamp <= _req.validityEndTimestamp,
            "Request expired"
        );
        require(_req.to != address(0), "recipient undefined");
        require(_req.quantity > 0, "0 qty");

        minted[_req.uid] = true;
    }

    /// @dev Recovers the signer from a message hash and signature.
    function _recoverSigner(bytes32 _messageHash, bytes memory _signature) internal view override returns (address) {
        return _hashTypedDataV4(_messageHash).recover(_signature);
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRequest(MintRequest calldata _req) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.signer,
                _req.to,
                _req.primarySaleRecipient,
                _req.quantity,
                _req.pricePerToken,
                _req.currency,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid
            );
    }
}
