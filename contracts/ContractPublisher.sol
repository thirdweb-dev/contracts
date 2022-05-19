// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

//  ==========  Internal imports    ==========
import { IContractPublisher } from "./interfaces/IContractPublisher.sol";

contract ContractPublisher is IContractPublisher, ERC2771Context, AccessControlEnumerable, Multicall {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The global Id for publicly published contracts.
    uint256 public nextPublicId = 1;

    /// @dev Whether the registry is paused.
    bool public isPaused;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Mapping from publisher address => operator address => whether publisher has approved operator
     *       to publish / unpublish contracts on their behalf.
     */
    mapping(address => mapping(address => bool)) public isApprovedByPublisher;

    /// @dev Mapping from public Id => publicly published contract.
    mapping(uint256 => PublicContract) private publicContracts;

    /// @dev Mapping from publisher address => set of published contracts.
    mapping(address => CustomContractSet) private contractsOfPublisher;

    /*///////////////////////////////////////////////////////////////
                    Constructor + modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether caller is publisher or approved by publisher.
    modifier onlyApprovedOrPublisher(address _publisher) {
        require(_msgSender() == _publisher || isApprovedByPublisher[_publisher][_msgSender()], "unapproved caller");

        _;
    }

    /// @dev Checks whether contract is unpaused or the caller is a contract admin.
    modifier onlyUnpausedOrAdmin() {
        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "registry paused");

        _;
    }

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                            Getter logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the latest version of all contracts published by a publisher.
    function getAllPublicPublishedContracts() external view returns (CustomContractInstance[] memory published) {
        uint256 net;

        for (uint256 i = 0; i < nextPublicId; i += 1) {
            PublicContract memory publicContract = publicContracts[i];
            if (publicContract.publisher != address(0)) {
                net += 1;
            }
        }

        published = new CustomContractInstance[](net);

        for (uint256 i = 0; i < net; i += 1) {
            PublicContract memory publicContract = publicContracts[i];
            if (publicContract.publisher != address(0)) {
                published[i] = contractsOfPublisher[publicContract.publisher]
                    .contracts[keccak256(bytes(publicContract.contractId))]
                    .latest;
            }
        }
    }

    /// @notice Returns the latest version of all contracts published by a publisher.
    function getAllPublishedContracts(address _publisher)
        external
        view
        returns (CustomContractInstance[] memory published)
    {
        uint256 total = EnumerableSet.length(contractsOfPublisher[_publisher].contractIds);

        published = new CustomContractInstance[](total);

        for (uint256 i = 0; i < total; i += 1) {
            bytes32 contractId = EnumerableSet.at(contractsOfPublisher[_publisher].contractIds, i);
            published[i] = contractsOfPublisher[_publisher].contracts[contractId].latest;
        }
    }

    /// @notice Returns all versions of a published contract.
    function getPublishedContractVersions(address _publisher, string memory _contractId)
        external
        view
        returns (CustomContractInstance[] memory published)
    {
        bytes32 id = keccak256(bytes(_contractId));
        uint256 total = contractsOfPublisher[_publisher].contracts[id].total;

        published = new CustomContractInstance[](total);

        for (uint256 i = 0; i < total; i += 1) {
            published[i] = contractsOfPublisher[_publisher].contracts[id].instances[i];
        }
    }

    /// @notice Returns the latest version of a contract published by a publisher.
    function getPublishedContract(address _publisher, string memory _contractId)
        external
        view
        returns (CustomContractInstance memory published)
    {
        published = contractsOfPublisher[_publisher].contracts[keccak256(bytes(_contractId))].latest;
    }

    /// @notice Returns the public id of a published contract, if it is public.
    function getPublicId(address _publisher, string memory _contractId) external view returns (uint256 publicId) {
        bytes32 contractIdInBytes = keccak256(bytes(_contractId));
        publicId = contractsOfPublisher[_publisher].contracts[contractIdInBytes].publicId;
    }

    /*///////////////////////////////////////////////////////////////
                            Publish logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Lets a publisher (caller) approve an operator to publish / unpublish contracts on their behalf.
    function approveOperator(address _operator, bool _toApprove) external {
        isApprovedByPublisher[_msgSender()][_operator] = _toApprove;
        emit Approved(_msgSender(), _operator, _toApprove);
    }

    /// @notice Let's an account publish a contract. The account must be approved by the publisher, or be the publisher.
    function publishContract(
        address _publisher,
        string memory _publishMetadataUri,
        bytes32 _bytecodeHash,
        address _implementation,
        string memory _contractId
    ) external onlyApprovedOrPublisher(_publisher) onlyUnpausedOrAdmin {
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

        emit ContractPublished(_msgSender(), _publisher, publishedContract);
    }

    /// @notice Lets an account unpublish a contract and all its versions. The account must be approved by the publisher, or be the publisher.
    function unpublishContract(address _publisher, string memory _contractId)
        external
        onlyApprovedOrPublisher(_publisher)
        onlyUnpausedOrAdmin
    {
        bytes32 contractIdInBytes = keccak256(bytes(_contractId));

        bool removed = EnumerableSet.remove(contractsOfPublisher[_publisher].contractIds, contractIdInBytes);
        require(removed, "given contractId DNE");

        delete contractsOfPublisher[_publisher].contracts[contractIdInBytes];

        emit ContractUnpublished(_msgSender(), _publisher, _contractId);
    }

    /// @notice Lets an account add a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.
    function addToPublicList(address _publisher, string memory _contractId) external {
        uint256 publicId = nextPublicId;
        nextPublicId += 1;

        bytes32 contractIdInBytes = keccak256(bytes(_contractId));

        PublicContract memory publicContract = PublicContract({ publisher: _publisher, contractId: _contractId });

        contractsOfPublisher[_publisher].contracts[contractIdInBytes].publicId = publicId;
        publicContracts[publicId] = publicContract;

        emit AddedContractToPublicList(_publisher, _contractId);
    }

    /// @notice Lets an account remove a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.
    function removeFromPublicList(address _publisher, string memory _contractId) external {
        bytes32 contractIdInBytes = keccak256(bytes(_contractId));
        uint256 publicId = contractsOfPublisher[_publisher].contracts[contractIdInBytes].publicId;

        delete contractsOfPublisher[_publisher].contracts[contractIdInBytes].publicId;

        delete publicContracts[publicId];

        emit RemovedContractToPublicList(_publisher, _contractId);
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

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
