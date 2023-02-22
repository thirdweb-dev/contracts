// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  thirdweb's `SignatureAction` extension smart contract can be used with any base smart contract. It provides a generic
 *  payload struct that can be signed by an authorized wallet and verified by the contract. The bytes `data` field provided
 *  in the payload can be abi encoded <-> decoded to use `SignatureContract` for any authorized signature action.
 */

interface ISignatureAction {
    /**
     *  @notice The payload that must be signed by an authorized wallet.
     *
     *  @param validityStartTimestamp The UNIX timestamp at and after which a signature is valid.
     *  @param validityEndTimestamp The UNIX timestamp at and after which a signature is invalid/expired.
     *  @param uid A unique non-repeatable ID for the payload.
     *  @param data Arbitrary bytes data to be used at the discretion of the contract.
     */
    struct GenericRequest {
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        bytes32 uid;
        bytes data;
    }

    /// @notice Emitted when a payload is verified and executed.
    event RequestExecuted(address indexed user, address indexed signer, GenericRequest _req);

    /**
     *  @notice Verfies that a payload is signed by an authorized wallet.
     *
     *  @param req The payload signed by the authorized wallet.
     *  @param signature The signature produced by the authorized wallet signing the given payload.
     *
     *  @return success Whether the payload is signed by the authorized wallet.
     *  @return signer The address of the signer.
     */
    function verify(GenericRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);
}
