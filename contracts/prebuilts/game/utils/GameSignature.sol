// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { IGameSignature } from "./IGameSignature.sol";
import { EIP712, ECDSA } from "../../../external-deps/openzeppelin/utils/cryptography/EIP712.sol";

abstract contract GameSignature is IGameSignature, EIP712 {
    using ECDSA for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256("GameRequest(uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid,bytes data)");

    mapping(bytes32 => bool) private executed;

    constructor() EIP712("GameSignature", "1") {}

    function _verify(GameRequest calldata _req, bytes calldata _signature)
        internal
        view
        returns (bool success, address signer)
    {
        signer = _recoverAddress(_req, _signature);
        success = !executed[_req.uid] && _isAuthorizedSigner(signer);
    }

    function _isAuthorizedSigner(address _signer) internal view virtual returns (bool);

    function _processRequest(GameRequest calldata _req, bytes calldata _signature) internal returns (address signer) {
        bool success;
        (success, signer) = _verify(_req, _signature);

        if (!success) {
            revert("Invalid req");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("Req expired");
        }

        executed[_req.uid] = true;
    }

    function _recoverAddress(GameRequest calldata _req, bytes calldata _signature) internal view returns (address) {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    function _encodeRequest(GameRequest calldata _req) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid,
                keccak256(_req.data)
            );
    }
}
