// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import "../utils/BaseTest.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { AccountPermissions } from "contracts/extension/upgradeable/AccountPermissions.sol";
import { AccountExtension } from "contracts/prebuilts/account/utils/AccountExtension.sol";

// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";

// Target
import { Account as SimpleAccount } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { ManagedAccountFactory, ManagedAccount } from "contracts/prebuilts/account/managed/ManagedAccountFactory.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { Seaport } from "./Seaport.sol";
import { EIP712MerkleTree } from "./EIP712MerkleTree.sol";
import { SeaportOrderEIP1271 } from "contracts/extension/SeaportOrderEIP1271.sol";

import { ConduitController } from "seaport-core/src/conduit/ConduitController.sol";
import { ConsiderationItem, OfferItem, ItemType, SpentItem, OrderComponents, Order, OrderParameters } from "seaport-types/src/lib/ConsiderationStructs.sol";
import { ConsiderationInterface } from "seaport-types/src/interfaces/ConsiderationInterface.sol";
import { OrderType, BasicOrderType } from "seaport-types/src/lib/ConsiderationEnums.sol";
import { OrderParameters } from "seaport-types/src/lib/ConsiderationStructs.sol";

import { Create2AddressDerivation_length, Create2AddressDerivation_ptr, EIP_712_PREFIX, EIP712_ConsiderationItem_size, EIP712_DigestPayload_size, EIP712_DomainSeparator_offset, EIP712_OfferItem_size, EIP712_Order_size, EIP712_OrderHash_offset, FreeMemoryPointerSlot, information_conduitController_offset, information_domainSeparator_offset, information_length, information_version_cd_offset, information_version_offset, information_versionLengthPtr, information_versionWithLength, MaskOverByteTwelve, MaskOverLastTwentyBytes, OneWord, OneWordShift, OrderParameters_consideration_head_offset, OrderParameters_counter_offset, OrderParameters_offer_head_offset, TwoWords } from "seaport-types/src/lib/ConsiderationConstants.sol";

import { BulkOrderProof_keyShift, BulkOrderProof_keySize, BulkOrder_Typehash_Height_One, BulkOrder_Typehash_Height_Two, BulkOrder_Typehash_Height_Three, BulkOrder_Typehash_Height_Four, BulkOrder_Typehash_Height_Five, BulkOrder_Typehash_Height_Six, BulkOrder_Typehash_Height_Seven, BulkOrder_Typehash_Height_Eight, BulkOrder_Typehash_Height_Nine, BulkOrder_Typehash_Height_Ten, BulkOrder_Typehash_Height_Eleven, BulkOrder_Typehash_Height_Twelve, BulkOrder_Typehash_Height_Thirteen, BulkOrder_Typehash_Height_Fourteen, BulkOrder_Typehash_Height_Fifteen, BulkOrder_Typehash_Height_Sixteen, BulkOrder_Typehash_Height_Seventeen, BulkOrder_Typehash_Height_Eighteen, BulkOrder_Typehash_Height_Nineteen, BulkOrder_Typehash_Height_Twenty, BulkOrder_Typehash_Height_TwentyOne, BulkOrder_Typehash_Height_TwentyTwo, BulkOrder_Typehash_Height_TwentyThree, BulkOrder_Typehash_Height_TwentyFour, EIP712_domainData_chainId_offset, EIP712_domainData_nameHash_offset, EIP712_domainData_size, EIP712_domainData_verifyingContract_offset, EIP712_domainData_versionHash_offset, FreeMemoryPointerSlot, NameLengthPtr, NameWithLength, OneWord, Slot0x80, ThreeWords, ZeroSlot } from "seaport-types/src/lib/ConsiderationConstants.sol";

library GPv2EIP1271 {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
}

interface EIP1271Verifier {
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

contract AccountBulkOrderSigTest is BaseTest {
    // Target contracts
    EntryPoint private entrypoint;
    ManagedAccountFactory private accountFactory;
    ConduitController private conduitController;
    Seaport private seaport;
    AccountExtension private accountExtension;
    SeaportOrderEIP1271 private seaportOrder;

    // Signer
    uint256 private accountAdminPKey = 1;
    address private accountAdmin;
    address private factoryDeployer = address(0x9876);

    // Test params
    bytes internal data = bytes("");

    OfferItem offerItem;
    OfferItem[] offerItems;
    ConsiderationItem considerationItem;
    ConsiderationItem[] considerationItems;
    OrderComponents baseOrderComponents;
    OrderParameters baseOrderParameters;

    // UserOp terminology: `sender` is the smart wallet.
    address private sender = 0xfD14C2809c876165D0c18878A2dE641018426a11;
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
        seaportOrder = new SeaportOrderEIP1271();
        entrypoint = new EntryPoint();

        // Setting up default extension.
        IExtension.Extension memory defaultExtension;

        accountExtension = new AccountExtension();
        defaultExtension.metadata = IExtension.ExtensionMetadata({
            name: "AccountExtension",
            metadataURI: "ipfs://AccountExtension",
            implementation: address(accountExtension)
        });

        defaultExtension.functions = new IExtension.ExtensionFunction[](9);

        defaultExtension.functions[0] = IExtension.ExtensionFunction(
            AccountExtension.supportsInterface.selector,
            "supportsInterface(bytes4)"
        );
        defaultExtension.functions[1] = IExtension.ExtensionFunction(
            AccountExtension.execute.selector,
            "execute(address,uint256,bytes)"
        );
        defaultExtension.functions[2] = IExtension.ExtensionFunction(
            AccountExtension.executeBatch.selector,
            "executeBatch(address[],uint256[],bytes[])"
        );
        defaultExtension.functions[3] = IExtension.ExtensionFunction(
            ERC721Holder.onERC721Received.selector,
            "onERC721Received(address,address,uint256,bytes)"
        );
        defaultExtension.functions[4] = IExtension.ExtensionFunction(
            ERC1155Holder.onERC1155Received.selector,
            "onERC1155Received(address,address,uint256,uint256,bytes)"
        );
        defaultExtension.functions[5] = IExtension.ExtensionFunction(
            bytes4(0), // Selector for `receive()` function.
            "receive()"
        );
        defaultExtension.functions[6] = IExtension.ExtensionFunction(
            AccountExtension.isValidSignature.selector,
            "isValidSignature(bytes32,bytes)"
        );
        defaultExtension.functions[7] = IExtension.ExtensionFunction(
            AccountExtension.addDeposit.selector,
            "addDeposit()"
        );
        defaultExtension.functions[8] = IExtension.ExtensionFunction(
            AccountExtension.withdrawDepositTo.selector,
            "withdrawDepositTo(address,uint256)"
        );

        IExtension.Extension[] memory extensions = new IExtension.Extension[](1);
        extensions[0] = defaultExtension;

        // deploy account factory
        vm.prank(factoryDeployer);
        accountFactory = new ManagedAccountFactory(
            factoryDeployer,
            IEntryPoint(payable(address(entrypoint))),
            extensions
        );
        // deploy seaport contract
        conduitController = new ConduitController();
        seaport = new Seaport(address(conduitController));

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

    /// @dev Make the account support Seaport bulk order signatures.
    function _upggradeIsValidSignature() internal {
        // Update isValidSignature to support Seaport bulk order signatures.
        IExtension.Extension memory extension;

        extension.metadata = IExtension.ExtensionMetadata({
            name: "SeaportOrderEIP1271",
            metadataURI: "ipfs://SeaportOrderEIP1271",
            implementation: address(seaportOrder)
        });

        extension.functions = new IExtension.ExtensionFunction[](1);

        extension.functions[0] = IExtension.ExtensionFunction(
            AccountExtension.isValidSignature.selector,
            "isValidSignature(bytes32,bytes)"
        );

        vm.prank(factoryDeployer);
        accountFactory.disableFunctionInExtension("AccountExtension", AccountExtension.isValidSignature.selector);

        vm.prank(factoryDeployer);
        accountFactory.addExtension(extension);
    }

    function test_POC() public {
        _upggradeIsValidSignature();

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
        bytes memory packedSignature = merkleTree.signBulkOrderSmartAccount(
            sender,
            ConsiderationInterface(address(seaport)),
            accountAdminPKey,
            orderComponents,
            uint24(0),
            false
        );

        Order memory order = Order({
            parameters: baseOrderParameters,
            signature: abi.encode(packedSignature, baseOrderParameters, seaport.getCounter(accountAdmin))
        });

        assertEq(packedSignature.length, 132);
        seaport.fulfillOrder{ value: 1 }(order, bytes32(0));
    }

    function test_incorrectCalldata() public {
        _upggradeIsValidSignature();

        bytes
            memory data = hex"1626ba7ee746d6438a7035da6bffb1190781d5571dff1452cbbce4796025977a58d7999c00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000041a60b8bc1318b87929d4de753d66e24fcacdf0c36d2377076215ac324f093cd7576abd55b273d88f88c5d7daa4b1b396e3dd239563ae4ca712d064d13afcde45d1b";

        (bool success, bytes memory result) = address(accountFactory).call(data);
    }

    function test_undo_upgrade() public {
        _upggradeIsValidSignature();
        assertEq(
            accountFactory.getImplementationForFunction(AccountExtension.isValidSignature.selector),
            address(seaportOrder)
        );

        vm.prank(factoryDeployer);
        accountFactory.removeExtension("SeaportOrderEIP1271");

        IExtension.ExtensionFunction memory func = IExtension.ExtensionFunction(
            AccountExtension.isValidSignature.selector,
            "isValidSignature(bytes32,bytes)"
        );
        vm.prank(factoryDeployer);
        accountFactory.enableFunctionInExtension("AccountExtension", func);

        assertEq(
            accountFactory.getImplementationForFunction(AccountExtension.isValidSignature.selector),
            address(accountExtension)
        );
    }
}
