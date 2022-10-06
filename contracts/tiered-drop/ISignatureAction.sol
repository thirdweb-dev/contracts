// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ISignatureAction {
    struct GenericRequest {
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        bytes32 uid;
        bytes data;
    }

    event RequestExecuted(address indexed user, address indexed signer, GenericRequest _req);

    function verify(GenericRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);

    function claimWithSignature(GenericRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (address signer);
}
