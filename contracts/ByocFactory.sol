// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

//  ==========  Internal imports    ==========
import { IByocFactory } from "./interfaces/IByocFactory.sol";
import { TWRegistry } from "./TWRegistry.sol";
import "./ThirdwebContract.sol";

contract ByocFactory is IByocFactory, ERC2771Context, AccessControlEnumerable, ThirdwebContract {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The main thirdweb registry.
    TWRegistry private immutable registry;

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
        ThirdwebContract.ThirdwebInfo memory _thirdwebInfo
    ) external onlyUnpausedOrAdmin returns (address deployedAddress) {
        require(bytes(_thirdwebInfo.publishMetadataUri).length > 0, "No publish metadata");

        bytes memory contractBytecode = abi.encodePacked(_contractBytecode, _constructorArgs);
        bytes32 salt = _salt == "" ? keccak256(abi.encodePacked(_msgSender(), block.number)) : _salt;

        deployedAddress = Create2.deploy(_value, salt, contractBytecode);

        ThirdwebContract(deployedAddress).setThirdwebInfo(_thirdwebInfo);
        require(
            keccak256(bytes(ThirdwebContract(deployedAddress).getPublishMetadataUri())) ==
                keccak256(bytes(_thirdwebInfo.publishMetadataUri)),
            "Not a thirdweb contract"
        );

        registry.add(_publisher, deployedAddress);

        emit ContractDeployed(_msgSender(), _publisher, deployedAddress);
    }

    /// @notice Deploys a clone pointing to an implementation of a published contract.
    function deployInstanceProxy(
        address _publisher,
        address _implementation,
        bytes memory _initializeData,
        bytes32 _salt,
        uint256 _value,
        ThirdwebContract.ThirdwebInfo memory _thirdwebInfo
    ) external onlyUnpausedOrAdmin returns (address deployedAddress) {
        bytes32 salt = _salt == "" ? keccak256(abi.encodePacked(_msgSender(), block.number)) : _salt;
        deployedAddress = Clones.cloneDeterministic(_implementation, salt);

        ThirdwebContract(deployedAddress).setThirdwebInfo(_thirdwebInfo);
        require(
            keccak256(bytes(ThirdwebContract(deployedAddress).getPublishMetadataUri())) ==
                keccak256(bytes(_thirdwebInfo.publishMetadataUri)),
            "Not a thirdweb contract"
        );

        registry.add(_publisher, deployedAddress);

        if (_initializeData.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCallWithValue(deployedAddress, _initializeData, _value);
        }

        emit ContractDeployed(_msgSender(), _publisher, deployedAddress);
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
