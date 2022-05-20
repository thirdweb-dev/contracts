// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

//  ==========  Internal imports    ==========
import { IContractMetadataRegistry } from "./interfaces/IContractMetadataRegistry.sol";

contract ContractMetadataRegistry is IContractMetadataRegistry, ERC2771Context, Multicall, AccessControlEnumerable {
    /// @dev Only accounts with OPERATOR_ROLE can register metadata for contracts.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*///////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev contract address deployed => metadata uri
    mapping(address => string) public getMetadataUri;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Records `metadataUri` as metadata for the contract at `contractAddress`.
    function registerMetadata(address contractAddress, string memory metadataUri) external {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Not operator.");
        require(bytes(metadataUri).length > 0, "No metadata");
        require(bytes(getMetadataUri[contractAddress]).length == 0, "Metadata already registered");

        getMetadataUri[contractAddress] = metadataUri;

        emit MetadataRegistered(contractAddress, metadataUri);
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous 
    //////////////////////////////////////////////////////////////*/

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
