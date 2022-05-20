// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

//  ==========  Internal imports    ==========
import { IContractDeployer } from "./interfaces/IContractDeployer.sol";
import { TWRegistry } from "./TWRegistry.sol";
import { IContractMetadataRegistry } from "./interfaces/IContractMetadataRegistry.sol";
import { ThirdwebContract } from "./ThirdwebContract.sol";

contract ContractDeployer is IContractDeployer, ERC2771Context, Multicall, AccessControlEnumerable {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The main thirdweb registry.
    TWRegistry private immutable registry;
    /// @dev The contract metadta registry.
    IContractMetadataRegistry private immutable metadataRegistry;
    /// @dev contract address deployed through the factory => deployer
    mapping(address => address) public getContractDeployer;

    /// @dev Whether the registry is paused.
    bool public isPaused;

    /*///////////////////////////////////////////////////////////////
                    Constructor + modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether contract is unpaused or the caller is a contract admin.
    modifier onlyUnpausedOrAdmin() {
        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "registry paused");

        _;
    }

    constructor(
        address _twRegistry,
        address _metadataRegistry,
        address _trustedForwarder
    ) ERC2771Context(_trustedForwarder) {
        registry = TWRegistry(_twRegistry);
        metadataRegistry = IContractMetadataRegistry(_metadataRegistry);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                            Deploy logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys an instance of a published contract directly.
    function deployInstance(
        address _publisher,
        bytes memory _contractBytecode,
        bytes memory _constructorArgs,
        bytes32 _salt,
        uint256 _value,
        string memory publishMetadataUri
    ) external onlyUnpausedOrAdmin returns (address deployedAddress) {
        require(bytes(publishMetadataUri).length > 0, "No publish metadata");

        address caller = _msgSender();

        bytes memory contractBytecode = abi.encodePacked(_contractBytecode, _constructorArgs);
        bytes32 salt = _salt == ""
            ? keccak256(abi.encodePacked(caller, block.number, keccak256(contractBytecode)))
            : keccak256(abi.encodePacked(caller, _salt));

        // compute the address of the clone and save it
        address computedContractAddress = Create2.computeAddress(salt, keccak256(contractBytecode), address(this));
        getContractDeployer[computedContractAddress] = caller;

        // deploy the contract
        deployedAddress = Create2.deploy(_value, salt, contractBytecode);

        // set the owner
        ThirdwebContract(deployedAddress).tw_initializeOwner(caller);

        // register to metadata registry
        metadataRegistry.registerMetadata(deployedAddress, publishMetadataUri);

        // register to TWRegistry
        registry.add(caller, deployedAddress);

        emit ContractDeployed(caller, _publisher, deployedAddress);
    }

    /// @notice Deploys a clone pointing to an implementation of a published contract.
    function deployInstanceProxy(
        address _publisher,
        address _implementation,
        bytes memory _initializeData,
        bytes32 _salt,
        uint256 _value,
        string memory publishMetadataUri
    ) external onlyUnpausedOrAdmin returns (address deployedAddress) {
        require(bytes(publishMetadataUri).length > 0, "No publish metadata");

        address caller = _msgSender();

        bytes32 salt = _salt == ""
            ? keccak256(abi.encodePacked(caller, block.number, _implementation, _initializeData))
            : keccak256(abi.encodePacked(caller, _salt));

        // compute the address of the clone and save it
        address computedContractAddress = Clones.predictDeterministicAddress(_implementation, salt, address(this));
        getContractDeployer[computedContractAddress] = caller;

        // deploy the clone
        deployedAddress = Clones.cloneDeterministic(_implementation, salt);

        // set the owner
        ThirdwebContract(deployedAddress).tw_initializeOwner(caller);

        // register to metadata registry
        metadataRegistry.registerMetadata(deployedAddress, publishMetadataUri);

        // register to TWRegistry
        registry.add(caller, deployedAddress);

        if (_initializeData.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCallWithValue(deployedAddress, _initializeData, _value);
        }

        emit ContractDeployed(caller, _publisher, deployedAddress);
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
