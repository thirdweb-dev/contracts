// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import "./interface/IExtensionRegistry.sol";
import "lib/dynamic-contracts/src/interface/IRouter.sol";

// Lib
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";
import "../eip/ERC165.sol";

// Extensions
import "./ExtensionRegistryState.sol";
import "./ExtensionRegistrySig.sol";
import "../extension/plugin/PermissionsEnumerableLogic.sol";

contract ExtensionRegistry is
    IExtensionRegistry,
    ExtensionRegistrySig,
    ExtensionRegistryState,
    PermissionsEnumerableLogic
{
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _defaultAdmin) EIP712("ExtensionRegistry", "1") {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            Modifier
    //////////////////////////////////////////////////////////////*/

    modifier onlyValidRequest(
        ExtensionUpdateRequest calldata _req,
        bytes calldata _signature,
        ExtensionUpdateType _targetUpdateType
    ) {
        _processRequest(_req, _signature);
        require(_req.caller == msg.sender, "ExtensionRegistry: unauthorized caller.");
        require(_req.updateType == _targetUpdateType, "ExtensionRegistry: invalid update type.");

        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a new extension to the registry.
    function addExtension(Extension memory _extension) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addExtension(_extension);

        emit ExtensionAdded(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @notice Adds a new extension to the registry via an authorized signature.
    function addExtensionWithSig(
        Extension memory _extension,
        ExtensionUpdateRequest calldata _req,
        bytes calldata _signature
    ) external onlyValidRequest(_req, _signature, ExtensionUpdateType.Add) {
        _addExtension(_extension);
        emit ExtensionAdded(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @notice Updates an existing extension in the registry.
    function updateExtension(Extension memory _extension) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateExtension(_extension);
        emit ExtensionUpdated(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @notice Updates an existing extension in the registry via an authorized signature.
    function updateExtensionWithSig(
        Extension memory _extension,
        ExtensionUpdateRequest calldata _req,
        bytes calldata _signature
    ) external onlyValidRequest(_req, _signature, ExtensionUpdateType.Update) {
        _updateExtension(_extension);
        emit ExtensionUpdated(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @notice Removes an existing extension from the registry.
    function removeExtension(string memory _extensionName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeExtension(_extensionName);
        emit ExtensionRemoved(_extensionName);
    }

    /// @notice Removes an existing extension from the registry via an authorized signature.
    function removeExtensionWithSig(
        string memory _extensionName,
        ExtensionUpdateRequest calldata _req,
        bytes calldata _signature
    ) external onlyValidRequest(_req, _signature, ExtensionUpdateType.Remove) {
        _removeExtension(_extensionName);
        emit ExtensionRemoved(_extensionName);
    }

    /// @notice Sets what extensions belong to the given contract type.
    function setExtensionsForContractType(string memory _contractType, string[] memory _extensionNames)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_extensionNames.length > 0, "ExtensionRegistry: no extensions provided.");
        require(bytes(_contractType).length > 0, "ExtensionRegistry: empty contract type.");
        _setExtensionsForContractType(_contractType, _extensionNames);
        emit ExtensionSetForContractType(_contractType, _extensionNames);
    }

    /// @notice Sets what extensions belong to the given contract type via an authorized signature.
    function setExtensionsForContractTypeWithSig(
        string memory _contractType,
        string[] memory _extensionNames,
        ExtensionUpdateRequest calldata _req,
        bytes calldata _signature
    ) external onlyValidRequest(_req, _signature, ExtensionUpdateType.SetupContractType) {
        _setExtensionsForContractType(_contractType, _extensionNames);
        emit ExtensionSetForContractType(_contractType, _extensionNames);
    }

    /// @notice Registers a contract with a contract type.
    function registerContract(string memory _contractType) external {
        address targetContract = msg.sender;
        _registerContract(_contractType, targetContract);

        emit ContractRegistered(targetContract, _contractType);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all extensions stored in the registry.
    function getAllExtensions() external view returns (Extension[] memory allExtensions) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        string[] memory names = data.extensionNames.values();
        uint256 len = names.length;

        allExtensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            uint256 latestId = data.nextIdForExtension[names[i]] - 1;
            allExtensions[i] = data.extensions[names[i]][latestId];
        }
    }

    /// @notice Returns the extension metadata and functions for a given extension.
    function getExtension(string memory _extensionName) public view returns (Extension memory) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        require(data.extensionNames.contains(_extensionName), "ExtensionRegistry: extension does not exist.");
        uint256 latestId = data.nextIdForExtension[_extensionName] - 1;
        return data.extensions[_extensionName][latestId];
    }

    /// @notice Returns all default extensions for a contract.
    function getAllDefaultExtensionsForContract(address _contract)
        external
        view
        returns (Extension[] memory extensions)
    {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        ExtensionID[] memory extensionIds = data.defaultExtensionsForContract[_contract];
        uint256 len = extensionIds.length;

        require(len > 0, "ExtensionRegistry: contract not registered.");

        extensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            extensions[i] = data.extensions[extensionIds[i].name][extensionIds[i].id];
        }
    }

    /// @notice Returns extension data for a default extension of a contract.
    function getDefaultExtensionForContract(string memory _extensionName, address _contract)
        external
        view
        returns (Extension memory extension)
    {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        require(data.extensionNames.contains(_extensionName), "ExtensionRegistry: extension does not exist.");

        ExtensionID[] memory extensionIds = data.defaultExtensionsForContract[_contract];
        uint256 len = extensionIds.length;

        require(len > 0, "ExtensionRegistry: contract not registered.");

        for (uint256 i = 0; i < len; i += 1) {
            if (keccak256(abi.encodePacked(extensionIds[i].name)) == keccak256(abi.encodePacked(_extensionName))) {
                return data.extensions[_extensionName][extensionIds[i].id];
            }
        }
    }

    /// @notice Returns extension metadata for the default extension associated with a function in a contract.
    function getExtensionForContractFunction(bytes4 _functionSelector, address _contract)
        external
        view
        returns (ExtensionMetadata memory)
    {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();

        ExtensionID[] memory extensionIds = data.defaultExtensionsForContract[_contract];
        uint256 len = extensionIds.length;

        require(len > 0, "ExtensionRegistry: contract not registered.");

        for (uint256 i = 0; i < len; i += 1) {
            bytes32 extHash = keccak256(abi.encodePacked(extensionIds[i].name, extensionIds[i].id));
            ExtensionMetadata memory metadata = data.extensionForFunction[_functionSelector][extHash];
            if (metadata.implementation != address(0)) {
                return metadata;
            }
        }

        revert("ExtensionRegistry: function not found for contract.");
    }

    /// @notice Returns all contract types stored in the registry.
    function getAllContractTypes() external view returns (string[] memory) {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        return data.allContractTypes.values();
    }

    /// @notice Returns the latest state of all extensions that belong to a contract type.
    function getLatestExtensionsForContractType(string memory _contractType)
        public
        view
        returns (Extension[] memory extensions)
    {
        ExtensionRegistryStateStorage.Data storage data = ExtensionRegistryStateStorage.extensionRegistryStateStorage();
        require(data.allContractTypes.contains(_contractType), "ExtensionRegistryState: contract type does not exist.");

        string[] memory extensionNames = data.extensionsForContractType[_contractType].values();
        uint256 len = extensionNames.length;
        extensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            string memory extensionName = extensionNames[i];
            uint256 extensionId = data.nextIdForExtension[extensionName] - 1;
            extensions[i] = data.extensions[extensionName][extensionId];
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a given address is authorized to sign requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _signer);
    }
}
