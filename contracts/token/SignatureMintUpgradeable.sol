// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../interfaces/token/ISignatureMint.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

abstract contract SignatureMintUpgradeable is Initializable, AccessControlEnumerableUpgradeable, EIP712Upgradeable, ISignatureMint {

    using ECDSAUpgradeable for bytes32;

    bytes32 internal constant TYPEHASH =
        keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
    
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

     /**
     * @dev See {_setURI}.
     */
    function __SignatureMint_init(string memory eip721Name, string memory eip712Version) internal onlyInitializing {
        __EIP712_init(eip721Name, eip712Version);

        __SignatureMint_init_unchained();
    }

    function __SignatureMint_init_unchained() internal onlyInitializing {}
    
    /// @dev Verifies that a mint request is signed by an account holding MINTER_ROLE (at the time of the function call).
    function verify(MintRequest calldata _req, bytes calldata _signature)
        public
        view
        returns (bool success, address signer)
    {
        signer = recoverAddress(_req, _signature);
        success = !minted[_req.uid] && hasRole(MINTER_ROLE, signer);
    }
    
    /// @dev Returns the address of the signer of the mint request.
    function recoverAddress(MintRequest calldata _req, bytes calldata _signature) internal view returns (address) {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRequest(MintRequest calldata _req) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.to,
                _req.royaltyRecipient,
                _req.royaltyBps,
                _req.primarySaleRecipient,
                _req.tokenId,
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