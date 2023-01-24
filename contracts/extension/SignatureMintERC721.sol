// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/ISignatureMintERC721.sol";
import "./ERC1271Support.sol";
import "../openzeppelin-presets/utils/cryptography/EIP712.sol";

abstract contract SignatureMintERC721 is EIP712, ERC1271Support, ISignatureMintERC721 {
    using ECDSA for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256(
            "MintRequest(address signer,address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

    constructor() EIP712("SignatureMintERC721", "1") {}

    /// @dev Verifies that a mint request is signed by an authorized account.
    function verify(MintRequest calldata _req, bytes calldata _signature)
        public
        view
        override
        returns (bool success, address signer)
    {
        signer = _req.signer;
        bytes32 messageHash = keccak256(_encodeRequest(_req));
        _validateSignature(messageHash, _signature, signer);
        success = !minted[_req.uid] && _canSignMintRequest(signer);
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _canSignMintRequest(address _signer) internal view virtual returns (bool);

    /// @dev Verifies a mint request and marks the request as minted.
    function _processRequest(MintRequest calldata _req, bytes calldata _signature) internal returns (address signer) {
        bool success;
        (success, signer) = verify(_req, _signature);

        if (!success) {
            revert("Invalid req");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("Req expired");
        }
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
                _req.royaltyRecipient,
                _req.royaltyBps,
                _req.primarySaleRecipient,
                keccak256(bytes(_req.uri)),
                _req.quantity,
                _req.pricePerToken,
                _req.currency,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid
            );
    }
}
