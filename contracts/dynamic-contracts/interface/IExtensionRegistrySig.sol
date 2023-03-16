// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IExtensionRegistrySig {
    enum ExtensionUpdateType {
        Add,
        Update,
        Remove,
        Build
    }

    /**
     *  @notice The payload that must be signed by an authorized wallet.
     *
     *  @param caller The address of the caller.
     *  @param updateType The type of update to be performed.
     *  @param uid A unique non-repeatable ID for the payload.
     *  @param validityStartTimestamp The UNIX timestamp at and after which a signature is valid.
     *  @param validityEndTimestamp The UNIX timestamp at and after which a signature is invalid/expired.
     */
    struct ExtensionUpdateRequest {
        address caller;
        ExtensionUpdateType updateType;
        bytes32 uid;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    /// @notice Emitted when a payload is verified and executed.
    event RequestExecuted(address indexed caller, address indexed signer, ExtensionUpdateRequest _req);

    /**
     *  @notice Verfies that a payload is signed by an authorized wallet.
     *
     *  @param req The payload signed by the authorized wallet.
     *  @param signature The signature produced by the authorized wallet signing the given payload.
     *
     *  @return success Whether the payload is signed by the authorized wallet.
     *  @return signer The address of the signer.
     */
    function verify(ExtensionUpdateRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);
}
