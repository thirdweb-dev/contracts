// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./openzeppelin-presets/metatx/ERC2771Context.sol";

//  ==========  Internal imports    ==========
import {IByocRegistry} from "./interfaces/IByocRegistry.sol";

contract ByocRegistry is IByocRegistry, ERC2771Context, AccessControlEnumerable {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Whether the registry is paused.
    bool public isPaused;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from publisher address => set of published contracts.
    mapping(address => CustomContractSet) private publishedContracts;

    /**
     *  @dev Mapping from publisher address => operator address => whether publisher has approved operator
     *       to publish / unpublish contracts on their behalf.
     */
    mapping(address => mapping(address => bool)) public isApprovedByPublisher;

    /// @dev Mapping from publisher address => publish metadata URI => contractId.
    mapping(address => mapping(string => uint256)) public contractId;

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

    constructor(address[] memory _trustedForwarders) ERC2771Context(_trustedForwarders) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                            Publish logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all contracts published by a publisher.
    function getAllPublishedContracts(address _publisher) external view returns (CustomContract[] memory published) {
        uint256 total = publishedContracts[_publisher].id;
        uint256 net = total - publishedContracts[_publisher].removed;

        published = new CustomContract[](net);

        uint256 publishedIndex;
        for (uint256 i = 0; i < total; i += 1) {
            if ((publishedContracts[_publisher].contractAtId[i].bytecodeHash).length == 0) {
                continue;
            }

            published[publishedIndex] = publishedContracts[_publisher].contractAtId[i];
            publishedIndex += 1;
        }
    }

    /// @notice Returns a given contract published by a publisher.
    function getPublishedContract(address _publisher, uint256 _contractId)
        external
        view
        returns (CustomContract memory)
    {
        return publishedContracts[_publisher].contractAtId[_contractId];
    }

    /// @notice Returns a group of contracts published by a publisher.
    function getPublishedContractGroup(address _publisher, bytes32 _groupId) external view returns (CustomContract[] memory published) {
        uint256 total = publishedContracts[_publisher].id;
        uint256 net;

        for(uint256 i = 0; i < total; i += 1) {
            if(publishedContracts[_publisher].contractAtId[i].groupId == _groupId) {
                net += 1;
            }
        }

        published = new CustomContract[](net);

        uint256 publishedIndex;
        for(uint256 i = 0; i < total; i += 1) {
            if(publishedContracts[_publisher].contractAtId[i].groupId == _groupId) {
                published[publishedIndex] = publishedContracts[_publisher].contractAtId[i];
                publishedIndex += 1;
            }
        }
    }

    /// @notice Let's an account publish a contract. The account must be approved by the publisher, or be the publisher.
    function publishContract(
        address _publisher,
        string memory _publishMetadataUri,
        bytes32 _bytecodeHash,
        address _implementation,
        bytes32 _groupId
    )
        external
        onlyApprovedOrPublisher(_publisher)
        onlyUnpausedOrAdmin
        returns (uint256 contractIdOfPublished)
    {
        contractIdOfPublished = publishedContracts[_publisher].id;
        publishedContracts[_publisher].id += 1;

        CustomContract memory publishedContract = CustomContract({
            contractId: contractIdOfPublished,
            publishMetadataUri: _publishMetadataUri,
            groupId: _groupId,
            bytecodeHash: _bytecodeHash,
            implementation: _implementation
        });

        publishedContracts[_publisher].contractAtId[contractIdOfPublished] = publishedContract;
        contractId[_publisher][_publishMetadataUri] = contractIdOfPublished;

        emit ContractPublished(_msgSender(), _publisher, contractIdOfPublished, publishedContract);
    }

    /// @notice Remove a contract from a publisher's set of published contracts.
    function unpublishContract(address _publisher, uint256 _contractId)
        external
        onlyApprovedOrPublisher(_publisher)
        onlyUnpausedOrAdmin
    {
        delete publishedContracts[_publisher].contractAtId[_contractId];
        publishedContracts[_publisher].removed += 1;

        emit ContractUnpublished(_msgSender(), _publisher, _contractId);
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

    /// @notice Lets a publisher (caller) approve an operator to publish / unpublish contracts on their behalf.
    function approveOperator(address _operator, bool _toApprove) external {
        isApprovedByPublisher[_msgSender()][_operator] = _toApprove;
        emit Approved(_msgSender(), _operator, _toApprove);
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
