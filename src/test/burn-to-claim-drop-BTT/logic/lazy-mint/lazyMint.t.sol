// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import { BurnToClaimDropERC721 } from "contracts/prebuilts/unaudited/burn-to-claim-drop/BurnToClaimDropERC721.sol";
import { BurnToClaimDrop721Logic, ERC721AUpgradeable, DelayedReveal, LazyMint, Drop, BurnToClaim, PrimarySale, PlatformFee } from "contracts/prebuilts/unaudited/burn-to-claim-drop/extension/BurnToClaimDrop721Logic.sol";
import { PermissionsEnumerableImpl } from "contracts/extension/upgradeable/impl/PermissionsEnumerableImpl.sol";
import { Royalty } from "contracts/extension/upgradeable/Royalty.sol";
import { BatchMintMetadata } from "contracts/extension/upgradeable/BatchMintMetadata.sol";
import { IBurnToClaim } from "contracts/extension/interface/IBurnToClaim.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { Permissions } from "contracts/extension/Permissions.sol";

contract BurnToClaimDropERC721Logic_LazyMint is BaseTest, IExtension {
    using Strings for uint256;
    using Strings for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);

    BurnToClaimDrop721Logic public drop;
    uint256 internal startId;
    uint256 internal amount;
    uint256[] internal batchIds;
    address internal caller;
    bytes internal data;
    bytes internal encryptedUri;
    bytes32 internal provenanceHash;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address dropImpl = address(new BurnToClaimDropERC721(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        drop = BurnToClaimDrop721Logic(
            payable(
                address(
                    new TWProxy(
                        dropImpl,
                        abi.encodeCall(
                            BurnToClaimDropERC721.initialize,
                            (
                                deployer,
                                NAME,
                                SYMBOL,
                                CONTRACT_URI,
                                forwarders(),
                                saleRecipient,
                                royaltyRecipient,
                                royaltyBps,
                                platformFeeBps,
                                platformFeeRecipient
                            )
                        )
                    )
                )
            )
        );

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);

        startId = 0;
        // mint 5 batches
        vm.startPrank(deployer);
        for (uint256 i = 0; i < 5; i++) {
            uint256 _amount = (i + 1) * 10;
            uint256 batchId = startId + _amount;
            batchIds.push(batchId);

            string memory baseURI = Strings.toString(batchId);
            startId = drop.lazyMint(_amount, baseURI, "");
        }
        vm.stopPrank();

        encryptedUri = bytes("ipfs://encryptedURI");
        provenanceHash = keccak256("provenanceHash");
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](2);

        // Extension: Permissions
        address permissions = address(new PermissionsEnumerableImpl());

        Extension memory extension_permissions;
        extension_permissions.metadata = ExtensionMetadata({
            name: "Permissions",
            metadataURI: "ipfs://Permissions",
            implementation: permissions
        });

        extension_permissions.functions = new ExtensionFunction[](1);
        extension_permissions.functions[0] = ExtensionFunction(
            Permissions.hasRole.selector,
            "hasRole(bytes32,address)"
        );

        extensions[0] = extension_permissions;

        address dropLogic = address(new BurnToClaimDrop721Logic());

        Extension memory extension_drop;
        extension_drop.metadata = ExtensionMetadata({
            name: "BurnToClaimDrop721Logic",
            metadataURI: "ipfs://BurnToClaimDrop721Logic",
            implementation: dropLogic
        });

        extension_drop.functions = new ExtensionFunction[](6);
        extension_drop.functions[0] = ExtensionFunction(BurnToClaimDrop721Logic.tokenURI.selector, "tokenURI(uint256)");
        extension_drop.functions[1] = ExtensionFunction(
            BurnToClaimDrop721Logic.lazyMint.selector,
            "lazyMint(uint256,string,bytes)"
        );
        extension_drop.functions[2] = ExtensionFunction(
            BatchMintMetadata.getBaseURICount.selector,
            "getBaseURICount()"
        );
        extension_drop.functions[3] = ExtensionFunction(
            BurnToClaimDrop721Logic.nextTokenIdToMint.selector,
            "nextTokenIdToMint()"
        );
        extension_drop.functions[4] = ExtensionFunction(
            DelayedReveal.encryptDecrypt.selector,
            "encryptDecrypt(bytes,bytes)"
        );
        extension_drop.functions[5] = ExtensionFunction(
            DelayedReveal.isEncryptedBatch.selector,
            "isEncryptedBatch(uint256)"
        );

        extensions[1] = extension_drop;
    }

    // ==================
    // ======= Test branch: when `data` empty
    // ==================

    function test_lazyMint_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert("Not authorized");
        drop.lazyMint(amount, "", "");
    }

    modifier whenCallerAuthorized() {
        caller = deployer;
        _;
    }

    function test_lazyMint_zeroAmount() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectRevert("0 amt");
        drop.lazyMint(amount, "", "");
    }

    modifier whenAmountNotZero() {
        amount = 50;
        _;
    }

    function test_lazyMint() public whenCallerAuthorized whenAmountNotZero {
        // check previous state
        uint256 _nextTokenIdToLazyMintOld = drop.nextTokenIdToMint();
        assertEq(_nextTokenIdToLazyMintOld, batchIds[4]);

        string memory baseURI = "ipfs://baseURI";

        // lazy mint next batch
        vm.prank(address(caller));
        uint256 _batchId = drop.lazyMint(amount, baseURI, "");

        // check new state
        assertEq(_batchId, _nextTokenIdToLazyMintOld + amount);
        for (uint256 i = _nextTokenIdToLazyMintOld; i < _batchId; i++) {
            assertEq(drop.tokenURI(i), string(abi.encodePacked(baseURI, i.toString())));
        }
        assertEq(drop.nextTokenIdToMint(), _nextTokenIdToLazyMintOld + amount);
        assertEq(drop.getBaseURICount(), batchIds.length + 1);
    }

    function test_lazyMint_event() public whenCallerAuthorized whenAmountNotZero {
        string memory baseURI = "ipfs://baseURI";
        uint256 _nextTokenIdToLazyMintOld = drop.nextTokenIdToMint();

        // lazy mint next batch
        vm.prank(address(caller));
        vm.expectEmit(true, false, false, true);
        emit TokensLazyMinted(_nextTokenIdToLazyMintOld, _nextTokenIdToLazyMintOld + amount - 1, baseURI, "");
        drop.lazyMint(amount, baseURI, "");
    }

    // ==================
    // ======= Test branch: when `data` not empty
    // ==================

    function test_lazyMint_withData_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert("Not authorized");
        drop.lazyMint(amount, "", data);
    }

    function test_lazyMint_withData_zeroAmount() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectRevert("0 amt");
        drop.lazyMint(amount, "", data);
    }

    function test_lazyMint_withData_incorrectData() public whenCallerAuthorized whenAmountNotZero {
        data = bytes("random data"); // not bytes+bytes32 encoded as expected
        vm.prank(address(caller));
        vm.expectRevert();
        drop.lazyMint(amount, "", data);
    }

    modifier whenCorrectEncodingOfData() {
        data = abi.encode(encryptedUri, provenanceHash);
        _;
    }

    function test_lazyMint_withData() public whenCallerAuthorized whenAmountNotZero whenCorrectEncodingOfData {
        // check previous state
        uint256 _nextTokenIdToLazyMintOld = drop.nextTokenIdToMint();
        assertEq(_nextTokenIdToLazyMintOld, batchIds[4]);

        string memory placeholderURI = "ipfs://placeholderURI";

        // lazy mint next batch
        vm.prank(address(caller));
        uint256 _batchId = drop.lazyMint(amount, placeholderURI, data);

        // check new state
        assertTrue(drop.isEncryptedBatch(_batchId)); // encrypted batch
        assertEq(_batchId, _nextTokenIdToLazyMintOld + amount);
        for (uint256 i = _nextTokenIdToLazyMintOld; i < _batchId; i++) {
            assertEq(drop.tokenURI(i), string(abi.encodePacked(placeholderURI, "0"))); // encrypted batch, hence token-id 0
        }
        assertEq(drop.nextTokenIdToMint(), _nextTokenIdToLazyMintOld + amount);
        assertEq(drop.getBaseURICount(), batchIds.length + 1);
    }

    function test_lazyMint_withData_event() public whenCallerAuthorized whenAmountNotZero whenCorrectEncodingOfData {
        string memory placeholderURI = "ipfs://placeholderURI";
        uint256 _nextTokenIdToLazyMintOld = drop.nextTokenIdToMint();

        // lazy mint next batch
        vm.prank(address(caller));
        vm.expectEmit(true, false, false, true);
        emit TokensLazyMinted(_nextTokenIdToLazyMintOld, _nextTokenIdToLazyMintOld + amount - 1, placeholderURI, data);
        drop.lazyMint(amount, placeholderURI, data);
    }
}
