// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  External imports    ==========
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../extension/Multicall.sol";

//  ==========  Internal imports    ==========
import { IContractPublisher } from "./interface/IContractPublisher.sol";

contract ContractPublisher is IContractPublisher, ERC2771Context, AccessControlEnumerable, Multicall {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether the contract publisher is paused.
    bool public isPaused;
    IContractPublisher public prevPublisher;

    /// @dev Only MIGRATION holders can override previous publisher or migrate data
    bytes32 private constant MIGRATION_ROLE = keccak256("MIGRATION_ROLE");

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from publisher address => set of published contracts.
    mapping(address => CustomContractSet) private contractsOfPublisher;
    /// @dev Mapping publisher address => profile uri
    mapping(address => string) private profileUriOfPublisher;
    /// @dev Mapping compilerMetadataUri => publishedMetadataUri
    mapping(string => PublishedMetadataSet) private compilerMetadataUriToPublishedMetadataUris;

    /*///////////////////////////////////////////////////////////////
                    Constructor + modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether caller is publisher TODO enable external approvals
    modifier onlyPublisher(address _publisher) {
        require(_msgSender() == _publisher, "unapproved caller");

        _;
    }

    /// @dev Checks whether contract is unpaused or the caller is a contract admin.
    modifier onlyUnpausedOrAdmin() {
        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "registry paused");

        _;
    }

    constructor(
        address _defaultAdmin,
        address _trustedForwarder,
        IContractPublisher _prevPublisher
    ) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MIGRATION_ROLE, _defaultAdmin);
        _setRoleAdmin(MIGRATION_ROLE, MIGRATION_ROLE);

        prevPublisher = _prevPublisher;
    }

    /*///////////////////////////////////////////////////////////////
                            Getter logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the latest version of all contracts published by a publisher.
    function getAllPublishedContracts(
        address _publisher
    ) external view returns (CustomContractInstance[] memory published) {
        CustomContractInstance[] memory linkedData;
        if (address(prevPublisher) != address(0)) {
            linkedData = prevPublisher.getAllPublishedContracts(_publisher);
        }
        uint256 currentTotal = EnumerableSet.length(contractsOfPublisher[_publisher].contractIds);
        uint256 prevTotal = linkedData.length;
        uint256 total = prevTotal + currentTotal;
        published = new CustomContractInstance[](total);
        // fill in previously published contracts
        for (uint256 i = 0; i < prevTotal; i += 1) {
            published[i] = linkedData[i];
        }
        // fill in current published contracts
        for (uint256 i = 0; i < currentTotal; i += 1) {
            bytes32 contractId = EnumerableSet.at(contractsOfPublisher[_publisher].contractIds, i);
            published[i + prevTotal] = contractsOfPublisher[_publisher].contracts[contractId].latest;
        }
    }

    /// @notice Returns all versions of a published contract.
    function getPublishedContractVersions(
        address _publisher,
        string memory _contractId
    ) external view returns (CustomContractInstance[] memory published) {
        CustomContractInstance[] memory linkedVersions;

        if (address(prevPublisher) != address(0)) {
            linkedVersions = prevPublisher.getPublishedContractVersions(_publisher, _contractId);
        }
        uint256 prevTotal = linkedVersions.length;

        bytes32 id = keccak256(bytes(_contractId));
        uint256 currentTotal = contractsOfPublisher[_publisher].contracts[id].total;
        uint256 total = prevTotal + currentTotal;

        published = new CustomContractInstance[](total);

        // fill in previously published contracts
        for (uint256 i = 0; i < prevTotal; i += 1) {
            published[i] = linkedVersions[i];
        }
        // fill in current published contracts
        for (uint256 i = 0; i < currentTotal; i += 1) {
            published[i + prevTotal] = contractsOfPublisher[_publisher].contracts[id].instances[i];
        }
    }

    /// @notice Returns the latest version of a contract published by a publisher.
    function getPublishedContract(
        address _publisher,
        string memory _contractId
    ) external view returns (CustomContractInstance memory published) {
        published = contractsOfPublisher[_publisher].contracts[keccak256(bytes(_contractId))].latest;
        // if not found, check the previous publisher
        if (address(prevPublisher) != address(0) && published.publishTimestamp == 0) {
            published = prevPublisher.getPublishedContract(_publisher, _contractId);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Publish logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Let's an account publish a contract.
    function publishContract(
        address _publisher,
        string memory _contractId,
        string memory _publishMetadataUri,
        string memory _compilerMetadataUri,
        bytes32 _bytecodeHash,
        address _implementation
    ) external onlyPublisher(_publisher) onlyUnpausedOrAdmin {
        CustomContractInstance memory publishedContract = CustomContractInstance({
            contractId: _contractId,
            publishTimestamp: block.timestamp,
            publishMetadataUri: _publishMetadataUri,
            bytecodeHash: _bytecodeHash,
            implementation: _implementation
        });

        bytes32 contractIdInBytes = keccak256(bytes(_contractId));
        EnumerableSet.add(contractsOfPublisher[_publisher].contractIds, contractIdInBytes);

        contractsOfPublisher[_publisher].contracts[contractIdInBytes].latest = publishedContract;

        uint256 index = contractsOfPublisher[_publisher].contracts[contractIdInBytes].total;
        contractsOfPublisher[_publisher].contracts[contractIdInBytes].total += 1;
        contractsOfPublisher[_publisher].contracts[contractIdInBytes].instances[index] = publishedContract;

        uint256 metadataIndex = compilerMetadataUriToPublishedMetadataUris[_compilerMetadataUri].index;
        compilerMetadataUriToPublishedMetadataUris[_compilerMetadataUri].uris[metadataIndex] = _publishMetadataUri;
        compilerMetadataUriToPublishedMetadataUris[_compilerMetadataUri].index = metadataIndex + 1;

        emit ContractPublished(_msgSender(), _publisher, publishedContract);
    }

    /// @notice Lets a publisher unpublish a contract and all its versions.
    function unpublishContract(
        address _publisher,
        string memory _contractId
    ) external onlyPublisher(_publisher) onlyUnpausedOrAdmin {
        bytes32 contractIdInBytes = keccak256(bytes(_contractId));

        bool removed = EnumerableSet.remove(contractsOfPublisher[_publisher].contractIds, contractIdInBytes);
        require(removed, "given contractId DNE");

        delete contractsOfPublisher[_publisher].contracts[contractIdInBytes];

        emit ContractUnpublished(_msgSender(), _publisher, _contractId);
    }

    function setPrevPublisher(IContractPublisher _prevPublisher) external {
        require(hasRole(MIGRATION_ROLE, _msgSender()), "Not authorized");
        prevPublisher = _prevPublisher;
    }

    /// @notice Lets an account set its own publisher profile uri
    function setPublisherProfileUri(address publisher, string memory uri) public {
        require(
            (!isPaused && _msgSender() == publisher) || hasRole(MIGRATION_ROLE, _msgSender()),
            "Registry paused or caller not authorized"
        );
        string memory currentURI = profileUriOfPublisher[publisher];
        profileUriOfPublisher[publisher] = uri;

        emit PublisherProfileUpdated(publisher, currentURI, uri);
    }

    // @notice Get a publisher profile uri
    function getPublisherProfileUri(address publisher) public view returns (string memory uri) {
        uri = profileUriOfPublisher[publisher];
        // if not found, check the previous publisher
        if (address(prevPublisher) != address(0) && bytes(uri).length == 0) {
            uri = prevPublisher.getPublisherProfileUri(publisher);
        }
    }

    /// @notice Retrieve the published metadata URI from a compiler metadata URI
    function getPublishedUriFromCompilerUri(
        string memory compilerMetadataUri
    ) public view returns (string[] memory publishedMetadataUris) {
        string[] memory linkedUris;
        if (address(prevPublisher) != address(0)) {
            linkedUris = prevPublisher.getPublishedUriFromCompilerUri(compilerMetadataUri);
        }
        uint256 prevTotal = linkedUris.length;
        uint256 currentTotal = compilerMetadataUriToPublishedMetadataUris[compilerMetadataUri].index;
        uint256 total = prevTotal + currentTotal;
        publishedMetadataUris = new string[](total);
        // fill in previously published uris
        for (uint256 i = 0; i < prevTotal; i += 1) {
            publishedMetadataUris[i] = linkedUris[i];
        }
        // fill in current published uris
        for (uint256 i = 0; i < currentTotal; i += 1) {
            publishedMetadataUris[i + prevTotal] = compilerMetadataUriToPublishedMetadataUris[compilerMetadataUri].uris[
                i
            ];
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous 
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin pause the registry.
    function setPause(bool _pause) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "unapproved caller");
        isPaused = _pause;
        emit Paused(_pause);
    }

    /// @dev ERC2771Context overrides
    function _msgSender() internal view virtual override(Context, ERC2771Context, Multicall) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    /// @dev ERC2771Context overrides
    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
