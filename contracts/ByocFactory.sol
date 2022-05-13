// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

//  ==========  Internal imports    ==========
import { IByocFactory } from "./interfaces/IByocFactory.sol";
import { TWRegistry } from "./TWRegistry.sol";
import "./ThirdwebContract.sol";

contract ByocFactory is IByocFactory, ERC2771Context, Multicall, AccessControlEnumerable {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The main thirdweb registry.
    TWRegistry private immutable registry;

    /// @dev Whether the registry is paused.
    bool public isPaused;

    /// @dev contract address deployed through the factory => deployer
    mapping(address => address) public getContractDeployer;

    /*///////////////////////////////////////////////////////////////
                    Constructor + modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether contract is unpaused or the caller is a contract admin.
    modifier onlyUnpausedOrAdmin() {
        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "registry paused");

        _;
    }

    constructor(address _twRegistry, address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        registry = TWRegistry(_twRegistry);
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

        address computedContractAddress = Create2.computeAddress(salt, keccak256(contractBytecode), address(this));
        getContractDeployer[computedContractAddress] = caller;

        deployedAddress = Create2.deploy(_value, salt, contractBytecode);

        ThirdwebContract(deployedAddress).setPublishMetadataUri(publishMetadataUri);
        require(
            keccak256(bytes(ThirdwebContract(deployedAddress).getPublishMetadataUri())) ==
                keccak256(bytes(publishMetadataUri)),
            "Not a thirdweb contract"
        );

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
        address caller = _msgSender();

        bytes32 salt = _salt == ""
            ? keccak256(abi.encodePacked(caller, block.number, _implementation, _initializeData))
            : keccak256(abi.encodePacked(caller, _salt));

        address computedContractAddress = Clones.predictDeterministicAddress(_implementation, salt, address(this));
        getContractDeployer[computedContractAddress] = caller;

        deployedAddress = Clones.cloneDeterministic(_implementation, salt);

        ThirdwebContract(deployedAddress).setPublishMetadataUri(publishMetadataUri);
        require(
            keccak256(bytes(ThirdwebContract(deployedAddress).getPublishMetadataUri())) ==
                keccak256(bytes(publishMetadataUri)),
            "Not a thirdweb contract"
        );

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
