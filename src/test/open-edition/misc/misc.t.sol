// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { IERC721AUpgradeable, OpenEditionERC721, ISharedMetadata } from "contracts/prebuilts/open-edition/OpenEditionERC721.sol";
import { NFTMetadataRenderer } from "contracts/lib/NFTMetadataRenderer.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "src/test/utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract HarnessOpenEditionERC721 is OpenEditionERC721 {
    function msgData() public view returns (bytes memory) {
        return _msgData();
    }
}

contract OpenEditionERC721Test_misc is BaseTest {
    OpenEditionERC721 public openEdition;
    HarnessOpenEditionERC721 public harnessOpenEdition;

    address private openEditionImpl;
    address private harnessImpl;

    address private receiver = 0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd;

    ISharedMetadata.SharedMetadataInfo public sharedMetadata;

    function setUp() public override {
        super.setUp();
        openEditionImpl = address(new OpenEditionERC721());
        vm.prank(deployer);
        openEdition = OpenEditionERC721(
            address(
                new TWProxy(
                    openEditionImpl,
                    abi.encodeCall(
                        OpenEditionERC721.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps
                        )
                    )
                )
            )
        );

        sharedMetadata = ISharedMetadata.SharedMetadataInfo({
            name: "Test",
            description: "Test",
            imageURI: "https://test.com",
            animationURI: "https://test.com"
        });
    }

    function deployHarness() internal {
        harnessImpl = address(new HarnessOpenEditionERC721());
        harnessOpenEdition = HarnessOpenEditionERC721(
            address(
                new TWProxy(
                    harnessImpl,
                    abi.encodeCall(
                        OpenEditionERC721.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps
                        )
                    )
                )
            )
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc
    //////////////////////////////////////////////////////////////*/

    modifier claimTokens() {
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = "0";
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        vm.prank(receiver, receiver);
        openEdition.claim(receiver, 100, address(erc20), 0, alp, "");
        _;
    }

    modifier callerOwner() {
        vm.startPrank(receiver);
        _;
    }

    modifier callerNotOwner() {
        _;
    }

    function test_tokenURI_revert_tokenDoesNotExist() public {
        vm.expectRevert(bytes("!ID"));
        openEdition.tokenURI(1);
    }

    function test_tokenURI_returnMetadata() public claimTokens {
        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);

        string memory uri = openEdition.tokenURI(1);
        assertEq(
            uri,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadata.name,
                description: sharedMetadata.description,
                imageURI: sharedMetadata.imageURI,
                animationURI: sharedMetadata.animationURI,
                tokenOfEdition: 1
            })
        );
    }

    function test_startTokenId_returnOne() public {
        assertEq(openEdition.startTokenId(), 1);
    }

    function test_totalMinted_returnZero() public {
        assertEq(openEdition.totalMinted(), 0);
    }

    function test_totalMinted_returnOneHundred() public claimTokens {
        assertEq(openEdition.totalMinted(), 100);
    }

    function test_nextTokenIdToMint_returnOne() public {
        assertEq(openEdition.nextTokenIdToMint(), 1);
    }

    function test_nextTokenIdToMint_returnOneHundredAndOne() public claimTokens {
        assertEq(openEdition.nextTokenIdToMint(), 101);
    }

    function test_nextTokenIdToClaim_returnOne() public {
        assertEq(openEdition.nextTokenIdToClaim(), 1);
    }

    function test_nextTokenIdToClaim_returnOneHundredAndOne() public claimTokens {
        assertEq(openEdition.nextTokenIdToClaim(), 101);
    }

    function test_burn_revert_callerNotOwner() public claimTokens callerNotOwner {
        vm.expectRevert(IERC721AUpgradeable.TransferCallerNotOwnerNorApproved.selector);
        openEdition.burn(1);
    }

    function test_burn_state_callerOwner() public claimTokens callerOwner {
        uint256 balanceBeforeBurn = openEdition.balanceOf(receiver);

        openEdition.burn(1);

        uint256 balanceAfterBurn = openEdition.balanceOf(receiver);

        assertEq(balanceBeforeBurn - balanceAfterBurn, 1);
    }

    function test_burn_state_callerApproved() public claimTokens {
        uint256 balanceBeforeBurn = openEdition.balanceOf(receiver);

        vm.prank(receiver);
        openEdition.setApprovalForAll(deployer, true);

        vm.prank(deployer);
        openEdition.burn(1);

        uint256 balanceAfterBurn = openEdition.balanceOf(receiver);

        assertEq(balanceBeforeBurn - balanceAfterBurn, 1);
    }

    function test_supportsInterface() public {
        assertEq(openEdition.supportsInterface(type(IERC2981Upgradeable).interfaceId), true);
        bytes4 invalidId = bytes4(0);
        assertEq(openEdition.supportsInterface(invalidId), false);
    }

    function test_msgData_returnValue() public {
        deployHarness();
        bytes memory msgData = harnessOpenEdition.msgData();
        bytes4 expectedData = harnessOpenEdition.msgData.selector;
        assertEq(bytes4(msgData), expectedData);
    }
}
