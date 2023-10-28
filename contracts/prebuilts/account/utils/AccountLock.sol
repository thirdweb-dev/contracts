// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { IAccountLock } from "../interface/IAccountLock.sol";
import { Guardian } from "contracts/prebuilts/account/utils/Guardian.sol";
import { Account } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { AccountGuardian } from "contracts/prebuilts/account/utils/AccountGuardian.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MockV3Aggregator } from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import { MockLinkToken } from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/automation/AutomationCompatibleInterface.sol";
import { KeeperRegistryBase2_0Mock } from "@chainlink/contracts/src/v0.8/mocks/KeeperRegistryBase2_0Mock.sol";
import { KeeperRegistry2_0Mock } from "@chainlink/contracts/src/v0.8/mocks/KeeperRegistry2_0Mock.sol";
import { KeeperRegistrar2_0Mock } from "@chainlink/contracts/src/v0.8/mocks/KeeperRegistrar2_0Mock.sol";

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}

contract AccountLock is IAccountLock, AutomationCompatibleInterface {
    Guardian public guardianContract;
    uint8 public constant DECIMAL = 8;
    int256 public constant INITIAL_LINK_PRICE = 2000e8;
    int256 public constant INITIAL_GAS_PRICE = 2e8;
    uint96 public constant FUND_UPKEEP_LINK_TOKEN = 5e18;
    uint256 public constant LOCK_REQUEST_TIME_TO_EVALUATION = 604800; // 7 days
    address[] internal _lockedAccounts;
    mapping(address => bytes32) private accountToLockRequest;
    mapping(bytes32 => uint256) private lockRequestToCreationTime;
    mapping(bytes32 => bool) private lockRequestEvaluationStatus;
    mapping(bytes32 => mapping(address => bytes)) public lockRequestToGuardianToSignature;
    mapping(bytes32 => mapping(address => bool)) lockRequestToGuardianToSignatureValid;

    ///////////////////////////////////////////
    ///// MOCKS  //////////////////////////////
    // (TODO: To be moved to a script file)//
    //////////////////////////////////////////

    MockLinkToken mockLinkToken = new MockLinkToken();

    MockV3Aggregator linkNativePriceFeed = new MockV3Aggregator(DECIMAL, INITIAL_LINK_PRICE);

    MockV3Aggregator fastGasPriceFeed = new MockV3Aggregator(DECIMAL, INITIAL_LINK_PRICE);

    KeeperRegistryBase2_0Mock keeperRegistryBase =
        new KeeperRegistryBase2_0Mock(
            KeeperRegistryBase2_0Mock.Mode.DEFAULT,
            address(mockLinkToken),
            address(linkNativePriceFeed),
            address(fastGasPriceFeed)
        );

    KeeperRegistry2_0Mock chainlinkKeeperRegistry = new KeeperRegistry2_0Mock(keeperRegistryBase);

    KeeperRegistrar2_0Mock chainlinkKeeperRegistrar =
        new KeeperRegistrar2_0Mock(
            address(mockLinkToken),
            KeeperRegistrar2_0Mock.AutoApproveType.ENABLED_ALL,
            type(uint16).max,
            address(chainlinkKeeperRegistry),
            FUND_UPKEEP_LINK_TOKEN
        );

    constructor(Guardian _guardian) {
        guardianContract = _guardian;
    }

    /////////////////////////////////
    /////// External Func ///////////
    /////////////////////////////////

    function createLockRequest(address account) external returns (bytes32) {
        /**
         * Step 1: check if the msg.sender is the guardian of the smartWallet account
         *
         * Step 2: Check the current status of the smart wallet (locked/unlocked) and if unlocked, check if any exisiting lock request exists. Revert if wallet is already locked or a lock req. exists
         *
         * Step 3: Create lock request (Encode -> Hashing)
         *
         * Step 4: Send request to all other guardians of this smart account
         **/

        address accountGuardian = guardianContract.getAccountGuardian(account);
        if (!AccountGuardian(accountGuardian).isAccountGuardian(msg.sender)) {
            revert NotAGuardian(account);
        }

        if (_isLocked(account)) {
            revert AccountAlreadyLocked(account);
        }

        if (activeLockRequestExists(account)) {
            revert ActiveLockRequestFound();
        }

        bytes32 lockRequestHash = keccak256(abi.encodePacked("_lockRequest(address account)", account));

        accountToLockRequest[account] = lockRequestHash;
        lockRequestToCreationTime[lockRequestHash] = block.timestamp;
        lockRequestEvaluationStatus[lockRequestHash] = false;

        bytes memory chainlinkUpkeepCheckData = abi.encode(lockRequestHash, account);

        _registerAndFundUpKeepForEvaluationUsingTimeBasedTrigger(chainlinkUpkeepCheckData);
        return lockRequestHash;
    }

    function recordSignatureOnLockRequest(bytes32 lockRequest, bytes calldata signature) external {
        lockRequestToGuardianToSignature[lockRequest][msg.sender] = signature;
    }

    //TODO: Add trigger to this function once lock request is created, using Chainlink Time based automation (Ref: https://docs.chain.link/chainlink-automation/overview/getting-started)
    function lockRequestEvaluation(bytes32 lockRequest, address account) public {
        uint256 validGuardianSignatures = 0;
        address accountGuardian = guardianContract.getAccountGuardian(account);
        address[] memory guardians = AccountGuardian(accountGuardian).getAllGuardians();
        uint256 guardianCount = guardians.length;

        for (uint256 g = 0; g < guardians.length; g++) {
            address guardian = guardians[g];
            bytes memory guardianSignature = lockRequestToGuardianToSignature[lockRequest][guardian];
            // checking if this guardian has signed the request
            if (guardianSignature.length > 0) {
                address recoveredGuardian = _verifyLockRequestSignature(lockRequest, guardianSignature);

                if (recoveredGuardian == guardian) {
                    lockRequestToGuardianToSignatureValid[lockRequest][guardian] = true;
                    validGuardianSignatures++;
                } else {
                    lockRequestToGuardianToSignatureValid[lockRequest][guardian] = false;
                }

                lockRequestEvaluationStatus[lockRequest] = true;
                if (validGuardianSignatures > (guardianCount / 2)) {
                    _lockAccount(payable(account));
                }
            }
        }
    }

    /////////////////////////////////
    /////// Chainlink Automation /////
    ////////////////////////////////

    function checkUpkeep(bytes memory checkData) public view returns (bool upkeepNeeded, bytes memory performData) {
        // assembly {
        //         mstore(add(lockRequest, 0x20), mload(add(checkData, 0x20)))
        //         mstore(add(account, 0x20), mload(add(checkData, 0x40)))
        //     }

        (bytes32 lockRequest, address account) = abi.decode(checkData, (bytes32, address));

        if (lockRequestEvaluationStatus[lockRequest]) {
            return (false, checkData);
        }

        uint256 lockRequestTimeElapsedSinceCreation = block.timestamp - lockRequestToCreationTime[lockRequest];

        if (lockRequestTimeElapsedSinceCreation >= LOCK_REQUEST_TIME_TO_EVALUATION) {
            return (true, checkData);
        } else {
            return (false, checkData);
        }
    }

    function performUpkeep(bytes calldata performData) external {
        (bool upkeepNeeded, bytes memory performData) = checkUpkeep(performData);

        if (upkeepNeeded) {
            // retrieving the lockRequest and account address from performData
            (bytes32 lockRequest, address account) = abi.decode(performData, (bytes32, address));

            lockRequestEvaluation(lockRequest, account);
        }
    }

    /////////////////////////////////
    /////// View Func //////////////
    ////////////////////////////////
    function activeLockRequestExists(address account) public view returns (bool) {
        if (accountToLockRequest[account].length > 0) {
            return true;
        } else {
            return false;
        }
    }

    function getLockRequests() external view returns (bytes32[] memory) {
        if (!guardianContract.isVerifiedGuardian(msg.sender)) {
            revert NotAGuardian(msg.sender);
        }

        address[] memory accounts = guardianContract.getAccountsTheGuardianIsGuarding(msg.sender);
        bytes32[] memory lockRequests = new bytes32[](accounts.length); // predefining the array length because it's stored in memory.

        // get lock req. of each account the guardian is guarding and return
        for (uint256 a = 0; a < accounts.length; a++) {
            lockRequests[a] = accountToLockRequest[accounts[a]];
        }

        return lockRequests;
    }

    /////////////////////////////////
    //// Internal Func /////////////
    /////////////////////////////////

    function _isLocked(address account) internal view returns (bool) {
        for (uint256 a = 0; a < _lockedAccounts.length; a++) {
            if (_lockedAccounts[a] == account) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Will lock all account assets and transactions
     * @param account The account to be locked
     */
    function _lockAccount(address payable account) internal {
        Account(account).setPaused(true);
    }

    function _verifyLockRequestSignature(
        bytes32 lockRequest,
        bytes memory guardianSignature
    ) internal returns (address) {
        // verify
        address recoveredGuardian = ECDSA.recover(lockRequest, guardianSignature);

        return recoveredGuardian;
    }

    /**
     * @notice Function to register & fund an upkeep that'll be responsible for evaluating the lock request responses using a time based Chainlink Automation
     */
    function _registerAndFundUpKeepForEvaluationUsingTimeBasedTrigger(bytes memory chainlinkUpkeepCheckData) internal {
        mockLinkToken.transferAndCall(address(chainlinkKeeperRegistrar), FUND_UPKEEP_LINK_TOKEN, "");

        KeeperRegistrar2_0Mock.RegistrationParams memory registrationParams = KeeperRegistrar2_0Mock
            .RegistrationParams({
                name: string(abi.encodePacked("Lock Request Upkeep", chainlinkUpkeepCheckData)),
                encryptedEmail: new bytes(0),
                upkeepContract: address(this),
                gasLimit: 500000,
                adminAddress: address(0x689EcF264657302052c3dfBD631e4c20d3ED0baB),
                checkData: chainlinkUpkeepCheckData,
                offchainConfig: new bytes(0),
                amount: 5e18
            });

        chainlinkKeeperRegistrar.registerUpkeep(registrationParams);
    }
}
