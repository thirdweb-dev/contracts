// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "contracts/extension/interface/ISignatureMintERC1155.sol";

contract SignatureMint1155Utils {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor() {
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 hashedName = keccak256(bytes("SignatureMintERC1155"));
        bytes32 hashedVersion = keccak256(bytes("1"));
        DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
    }

    bytes32 internal constant TYPEHASH =
        keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    // computes the hash of a permit
    function getStructHash(ISignatureMintERC1155.MintRequest memory _req) internal pure returns (bytes32) {
        return
            keccak256(
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
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(ISignatureMintERC1155.MintRequest memory _req) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_req)));
    }
}
