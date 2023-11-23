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

contract BurnToClaimDropERC721Logic_Reveal is BaseTest, IExtension {
    using Strings for uint256;
    using Strings for address;

    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    BurnToClaimDrop721Logic public drop;
    uint256 internal startId;
    uint256 internal amount;
    uint256[] internal batchIds;
    address internal caller;
    bytes internal data;
    string internal placeholderURI;
    bytes internal originalURI;
    uint256 internal _index;
    bytes internal _key;

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
        originalURI = bytes("ipfs://originalURI");
        placeholderURI = "ipfs://placeholderURI";
        _key = "key123";
        // mint 3 batches
        vm.startPrank(deployer);
        for (uint256 i = 0; i < 3; i++) {
            uint256 _amount = (i + 1) * 10;
            uint256 batchId = startId + _amount;
            batchIds.push(batchId);

            // set encrypted uri for one of the batches
            if (i == 1) {
                bytes memory _encryptedURI = drop.encryptDecrypt(originalURI, _key);
                bytes32 _provenanceHash = keccak256(abi.encodePacked(originalURI, _key, block.chainid));

                startId = drop.lazyMint(_amount, placeholderURI, abi.encode(_encryptedURI, _provenanceHash));
            } else {
                startId = drop.lazyMint(_amount, string(originalURI), "");
            }
        }
        vm.stopPrank();
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
            BurnToClaimDrop721Logic.reveal.selector,
            "reveal(uint256,bytes)"
        );
        extension_drop.functions[3] = ExtensionFunction(
            DelayedReveal.encryptDecrypt.selector,
            "encryptDecrypt(bytes,bytes)"
        );
        extension_drop.functions[4] = ExtensionFunction(
            DelayedReveal.isEncryptedBatch.selector,
            "isEncryptedBatch(uint256)"
        );
        extension_drop.functions[5] = ExtensionFunction(
            DelayedReveal.getRevealURI.selector,
            "getRevealURI(uint256,bytes)"
        );

        extensions[1] = extension_drop;
    }

    function test_reveal_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert("Not authorized");
        drop.lazyMint(amount, "", "");
    }

    modifier whenCallerAuthorized() {
        caller = deployer;
        _;
    }

    function test_reveal_invalidIndex() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectRevert("Invalid index");
        drop.reveal(4, "key");
    }

    modifier whenValidIndex() {
        _;
    }

    function test_reveal_noEncryptedURI() public whenCallerAuthorized whenValidIndex {
        _index = 2;
        vm.prank(address(caller));
        vm.expectRevert("Nothing to reveal");
        drop.reveal(_index, "key");
    }

    modifier whenEncryptedURI() {
        _index = 1;
        _;
    }

    function test_reveal_incorrectKey() public whenCallerAuthorized whenValidIndex whenEncryptedURI {
        vm.prank(address(caller));
        vm.expectRevert("Incorrect key");
        drop.reveal(_index, "incorrect key");
    }

    modifier whenCorrectKey() {
        _;
    }

    function test_reveal() public whenCallerAuthorized whenValidIndex whenEncryptedURI {
        //state before
        for (uint256 i = 0; i < 3; i++) {
            uint256 _startId = i > 0 ? batchIds[i - 1] : 0;

            for (uint256 j = _startId; j < batchIds[i]; j += 1) {
                string memory uri = drop.tokenURI(j);
                if (i == 1) {
                    assertEq(uri, string(abi.encodePacked(placeholderURI, "0"))); // <-- placeholder URI for encrypted batch
                } else {
                    assertEq(uri, string(abi.encodePacked(string(originalURI), j.toString())));
                }
            }
        }

        // reveal
        vm.prank(address(caller));
        string memory revealedURI = drop.reveal(_index, _key);

        // check state after
        vm.expectRevert("Nothing to reveal");
        drop.getRevealURI(_index, _key);

        assertEq(revealedURI, string(originalURI));

        for (uint256 i = 0; i < 3; i++) {
            uint256 _startId = i > 0 ? batchIds[i - 1] : 0;

            for (uint256 j = _startId; j < batchIds[i]; j += 1) {
                string memory uri = drop.tokenURI(j);
                assertEq(uri, string(abi.encodePacked(string(originalURI), j.toString())));
            }
        }
    }

    function test_reveal_event() public whenCallerAuthorized whenValidIndex whenEncryptedURI {
        vm.prank(address(caller));
        vm.expectEmit(true, false, false, true);
        emit TokenURIRevealed(1, string(originalURI));
        drop.reveal(_index, _key);
    }
}
