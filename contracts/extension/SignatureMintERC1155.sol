// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/ISignatureMintERC1155.sol";
import "../external-deps/openzeppelin/utils/cryptography/EIP712.sol";

abstract contract SignatureMintERC1155 is EIP712, ISignatureMintERC1155 {
    using ECDSA for bytes32;

    bytes32 internal constant TYPEHASH =
        keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

    constructor() EIP712("SignatureMintERC1155", "1") {}

    /// @dev Verifies that a mint request is signed by an account holding MINTER_ROLE (at the time of the function call).
    function verify(MintRequest calldata _req, bytes calldata _signature)
        public
        view
        override
        returns (bool success, address signer)
    {
        signer = _recoverAddress(_req, _signature);
        success = !minted[_req.uid] && _canSignMintRequest(signer);
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _canSignMintRequest(address _signer) internal view virtual returns (bool);

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

    /// @dev Returns the address of the signer of the mint request.
    function _recoverAddress(MintRequest calldata _req, bytes calldata _signature) internal view returns (address) {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRequest(MintRequest calldata _req) internal pure returns (bytes memory) {
        return
            bytes.concat(
                abi.encode(
                    TYPEHASH,
                    _req.to,
                    _req.royaltyRecipient,
                    _req.royaltyBps,
                    _req.primarySaleRecipient,
                    _req.tokenId,
                    keccak256(bytes(_req.uri))
                ),
                abi.encode(
                    _req.quantity,
                    _req.pricePerToken,
                    _req.currency,
                    _req.validityStartTimestamp,
                    _req.validityEndTimestamp,
                    _req.uid
                )
            );
    }
}
