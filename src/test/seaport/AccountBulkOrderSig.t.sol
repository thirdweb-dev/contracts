// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import "../utils/BaseTest.sol";

// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";

// Target
import { AccountFactory, Account as SimpleAccount } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { Seaport } from "./Seaport.sol";
import { EIP712MerkleTree } from "./EIP712MerkleTree.sol";

import { ConduitController } from "seaport-core/src/conduit/ConduitController.sol";
import { ConsiderationItem, OfferItem, ItemType, SpentItem, OrderComponents, Order, OrderParameters } from "seaport-types/src/lib/ConsiderationStructs.sol";
import { ConsiderationInterface } from "seaport-types/src/interfaces/ConsiderationInterface.sol";
import { OrderType, BasicOrderType } from "seaport-types/src/lib/ConsiderationEnums.sol";

library GPv2EIP1271 {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
}

interface EIP1271Verifier {
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

contract AccountBulkOrderSigTest is BaseTest {
    // Target contracts
    EntryPoint private entrypoint;
    AccountFactory private accountFactory;
    Seaport private seaport;

    // Signer
    uint256 private accountAdminPKey = 1;
    address private accountAdmin;

    // Test params
    OfferItem offerItem;
    OfferItem[] offerItems;
    ConsiderationItem considerationItem;
    ConsiderationItem[] considerationItems;
    OrderComponents baseOrderComponents;
    OrderParameters baseOrderParameters;

    // UserOp terminology: `sender` is the smart wallet.
    address private sender = 0xAcF86fd6BA3b8A4CBDbc1F0A605e1667a8879640;
    address payable private beneficiary = payable(address(0x45654));

    function _configureOrderParameters(address offerer) internal {
        bytes32 conduitKey = bytes32(0);
        baseOrderParameters.offerer = offerer;
        baseOrderParameters.zone = address(0);
        baseOrderParameters.offer = offerItems;
        baseOrderParameters.consideration = considerationItems;
        baseOrderParameters.orderType = OrderType.FULL_OPEN;
        baseOrderParameters.startTime = block.timestamp;
        baseOrderParameters.endTime = block.timestamp + 1;
        baseOrderParameters.zoneHash = bytes32(0);
        baseOrderParameters.salt = 0;
        baseOrderParameters.conduitKey = conduitKey;
        baseOrderParameters.totalOriginalConsiderationItems = considerationItems.length;
    }

    function _configureConsiderationItems() internal {
        considerationItem.itemType = ItemType.NATIVE;
        considerationItem.token = address(0);
        considerationItem.identifierOrCriteria = 0;
        considerationItem.startAmount = 1;
        considerationItem.endAmount = 1;
        considerationItem.recipient = payable(address(0x123));
        considerationItems.push(considerationItem);
    }

    function configureOrderComponents(uint256 counter) internal {
        baseOrderComponents.offerer = baseOrderParameters.offerer;
        baseOrderComponents.zone = baseOrderParameters.zone;
        baseOrderComponents.offer = baseOrderParameters.offer;
        baseOrderComponents.consideration = baseOrderParameters.consideration;
        baseOrderComponents.orderType = baseOrderParameters.orderType;
        baseOrderComponents.startTime = baseOrderParameters.startTime;
        baseOrderComponents.endTime = baseOrderParameters.endTime;
        baseOrderComponents.zoneHash = baseOrderParameters.zoneHash;
        baseOrderComponents.salt = baseOrderParameters.salt;
        baseOrderComponents.conduitKey = baseOrderParameters.conduitKey;
        baseOrderComponents.counter = counter;
    }

    function _setupUserOp(
        uint256 _signerPKey,
        bytes memory _initCode,
        bytes memory _callDataForEntrypoint
    ) internal returns (UserOperation[] memory ops) {
        uint256 nonce = entrypoint.getNonce(sender, 0);

        // Get user op fields
        UserOperation memory op = UserOperation({
            sender: sender,
            nonce: nonce,
            initCode: _initCode,
            callData: _callDataForEntrypoint,
            callGasLimit: 500_000,
            verificationGasLimit: 500_000,
            preVerificationGas: 500_000,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });

        // Sign UserOp
        bytes32 opHash = EntryPoint(entrypoint).getUserOpHash(op);
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(opHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPKey, msgHash);
        bytes memory userOpSignature = abi.encodePacked(r, s, v);

        address recoveredSigner = ECDSA.recover(msgHash, v, r, s);
        address expectedSigner = vm.addr(_signerPKey);
        assertEq(recoveredSigner, expectedSigner);

        op.signature = userOpSignature;

        // Store UserOp
        ops = new UserOperation[](1);
        ops[0] = op;
    }

    function _setupUserOpExecute(
        uint256 _signerPKey,
        bytes memory _initCode,
        address _target,
        uint256 _value,
        bytes memory _callData
    ) internal returns (UserOperation[] memory) {
        bytes memory callDataForEntrypoint = abi.encodeWithSignature(
            "execute(address,uint256,bytes)",
            _target,
            _value,
            _callData
        );

        return _setupUserOp(_signerPKey, _initCode, callDataForEntrypoint);
    }

    function setUp() public override {
        super.setUp();

        // Setup signers.
        string memory offerer = "offerer";
        (address addr, uint256 key) = makeAddrAndKey(offerer);

        accountAdmin = addr;
        accountAdminPKey = key;
        vm.deal(accountAdmin, 100 ether);

        // Setup contracts
        entrypoint = new EntryPoint();
        // deploy account factory
        accountFactory = new AccountFactory(deployer, IEntryPoint(payable(address(entrypoint))));
        // deploy seaport contract
        seaport = new Seaport(address(new ConduitController()));

        bytes memory initCallData = abi.encodeWithSignature("createAccount(address,bytes)", accountAdmin, bytes(""));
        bytes memory initCode = abi.encodePacked(abi.encodePacked(address(accountFactory)), initCallData);

        UserOperation[] memory userOpCreateAccount = _setupUserOpExecute(
            accountAdminPKey,
            initCode,
            address(0),
            0,
            bytes("")
        );

        EntryPoint(entrypoint).handleOps(userOpCreateAccount, beneficiary);
    }

    /*//////////////////////////////////////////////////////////
                    Test: performing a contract call
    //////////////////////////////////////////////////////////////*/

    function test_POC() public {
        erc721.mint(address(accountAdmin), 1);
        vm.prank(accountAdmin);
        erc721.setApprovalForAll(address(seaport), true);

        _configureConsiderationItems();
        _configureOrderParameters(sender);
        // _configureOrderParameters(accountAdmin);
        configureOrderComponents(seaport.getCounter(accountAdmin));
        OrderComponents[] memory orderComponents = new OrderComponents[](3);
        orderComponents[0] = baseOrderComponents;
        // The other order components can remain empty.

        EIP712MerkleTree merkleTree = new EIP712MerkleTree();
        bytes memory bulkSignature = merkleTree.signBulkOrder(
            ConsiderationInterface(address(seaport)),
            accountAdminPKey,
            orderComponents,
            uint24(0),
            false
        );

        Order memory order = Order({ parameters: baseOrderParameters, signature: bulkSignature });

        assertEq(bulkSignature.length, 132);
        vm.expectRevert("ECDSA: invalid signature length");
        seaport.fulfillOrder{ value: 1 }(order, bytes32(0));
    }
}
