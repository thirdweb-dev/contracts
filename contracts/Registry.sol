// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// CREATE2 -- contract deployment.
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Access Control
import "@openzeppelin/contracts/access/Ownable.sol";

// Protocol Components
import { IControlDeployer } from "./interfaces/IControlDeployer.sol";
import { Forwarder } from "./Forwarder.sol";
import { ProtocolControl } from "./ProtocolControl.sol";

contract Registry is Context, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant MAX_PROVIDER_FEE_BPS = 1000; // 10%
    uint256 public defaultFeeBps = 500; // 5%

    mapping(address => uint256) controlFeeBps;

    // service provider / admin treasury
    address public treasury;

    // `Forwarder` for meta-transacitons
    address public forwarder;

    IControlDeployer public deployer;

    // Mapping from app deployer => app address.
    mapping(address => EnumerableSet.AddressSet) private _protocolControls;
    mapping(address => uint256) public protocolControlFeeBps;

    // Emitted when the treasury is updated
    event TreasuryUpdated(address newTreasury);

    event DeployerUpdated(address newDeployer);

    // Emitted on fees updates
    event DefaultFeeBpsUpdated(uint256 defaultFeeBps);
    event ProtocolControlFeeBpsUpdated(address indexed control, uint256 defaultFeeBps);

    constructor(
        address _treasury,
        address _forwarder,
        address _deployer
    ) {
        treasury = _treasury;
        forwarder = _forwarder;
        deployer = IControlDeployer(_deployer);
    }

    function deployProtocol(string memory uri) external {
        uint256 currentIndex = _protocolControls[_msgSender()].length();

        address controlAddress = deployer.deployControl(address(this), currentIndex, _msgSender(), uri);

        _protocolControls[_msgSender()].add(controlAddress);
    }

    /// @dev Returns the latest version of protocol control
    function getProtocolControlCount(address deployer) external view returns (uint256) {
        return _protocolControls[deployer].length();
    }

    /// @dev Returns the protocol control address for the given version
    function getProtocolControl(address deployer, uint256 index) external view returns (address) {
        return _protocolControls[deployer].at(index);
    }

    function setDeployer(address _newDeployer) external onlyOwner {
        deployer = IControlDeployer(_newDeployer);

        emit DeployerUpdated(_newDeployer);
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        treasury = _newTreasury;

        emit TreasuryUpdated(_newTreasury);
    }

    function setDefaultFeeBps(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= MAX_PROVIDER_FEE_BPS, "Registry: provider fee cannot be greater than 10%");

        defaultFeeBps = _newFeeBps;

        emit DefaultFeeBpsUpdated(_newFeeBps);
    }

    function setProtocolControlFeeBps(address protocolControl, uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= MAX_PROVIDER_FEE_BPS, "Registry: provider fee cannot be greater than 10%");

        protocolControlFeeBps[protocolControl] = _newFeeBps;

        emit ProtocolControlFeeBpsUpdated(protocolControl, _newFeeBps);
    }

    function getFeeBps(address protocolControl) external view returns (uint256) {
        uint256 fees = protocolControlFeeBps[protocolControl];
        if (fees == 0) {
            return defaultFeeBps;
        }
        return fees;
    }
}
