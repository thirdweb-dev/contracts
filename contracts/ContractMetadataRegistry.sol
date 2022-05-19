// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

//  ==========  Internal imports    ==========
import { IContractMetadataRegistry } from "./interfaces/IContractMetadataRegistry.sol";

contract ContractMetadataRegistry is IContractMetadataRegistry, ERC2771Context, Multicall, AccessControlEnumerable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev contract address deployed => metadata uri
    mapping(address => string) public getMetadataUri;

    /*///////////////////////////////////////////////////////////////
                    Constructor + modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether the caller is a contract admin.
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must be admin");

        _;
    }

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                            External methods
    //////////////////////////////////////////////////////////////*/

    function registerMetadata(address contractAddress, string memory metadataUri) external onlyAdmin {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "not operator.");
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
