// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/drop/DropERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Test imports
import "../utils/BaseTest.sol";

contract SubExploitContract is ERC721Holder, ERC1155Holder {
    DropERC721 internal drop;
    address payable internal master;

    // using Strings for uint256;

    // using Strings for uint256;

    constructor(address _drop) {
        drop = DropERC721(_drop);
        master = payable(msg.sender);
    }

    /// @dev Lets an account claim NFTs.
    function claimDrop(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external {
        drop.claim(_receiver, _quantity, _currency, _pricePerToken, _proofs, _proofMaxQuantityPerTransaction);

        selfdestruct(master);
    }
}

contract MasterExploitContract is ERC721Holder, ERC1155Holder {
    address internal drop;

    constructor(address _drop) {
        drop = _drop;
    }

    /// @dev Lets an account claim NFTs.
    function performExploit(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external {
        for (uint256 i = 0; i < 100; i++) {
            SubExploitContract sub = new SubExploitContract(address(drop));
            sub.claimDrop(_receiver, _quantity, _currency, _pricePerToken, _proofs, _proofMaxQuantityPerTransaction);
        }
    }
}

contract DropERC721Test is BaseTest {
    DropERC721 public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
    }

    function test_claimCondition_startIdAndCount() public {
        vm.startPrank(deployer);

        uint256 currentStartId = 0;
        uint256 count = 0;

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](2);
        conditions[0].startTimestamp = 0;
        conditions[0].maxClaimableSupply = 10;
        conditions[1].startTimestamp = 1;
        conditions[1].maxClaimableSupply = 10;

        drop.setClaimConditions(conditions, false);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, false);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, true);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 2);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, true);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 4);
        assertEq(count, 2);
    }

    function test_claimCondition_startPhase() public {
        vm.startPrank(deployer);

        uint256 activeConditionId = 0;

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](3);
        conditions[0].startTimestamp = 10;
        conditions[0].maxClaimableSupply = 11;
        conditions[0].quantityLimitPerTransaction = 12;
        conditions[0].waitTimeInSecondsBetweenClaims = 13;
        conditions[1].startTimestamp = 20;
        conditions[1].maxClaimableSupply = 21;
        conditions[1].quantityLimitPerTransaction = 22;
        conditions[1].waitTimeInSecondsBetweenClaims = 23;
        conditions[2].startTimestamp = 30;
        conditions[2].maxClaimableSupply = 31;
        conditions[2].quantityLimitPerTransaction = 32;
        conditions[2].waitTimeInSecondsBetweenClaims = 33;
        drop.setClaimConditions(conditions, false);

        vm.expectRevert("!CONDITION.");
        drop.getActiveClaimConditionId();

        vm.warp(10);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 0);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 10);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 11);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 12);
        assertEq(drop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 13);

        vm.warp(20);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 1);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 20);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 21);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 22);
        assertEq(drop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 23);

        vm.warp(30);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 2);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 30);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 31);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 32);
        assertEq(drop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 33);

        vm.warp(40);
        assertEq(drop.getActiveClaimConditionId(), 2);
    }

    function test_claimCondition_waitTimeInSecondsBetweenClaims() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 1, address(0), 0, proofs, 0);

        vm.expectRevert("cannot claim.");
        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 1, address(0), 0, proofs, 0);
    }

    function test_claimCondition_resetEligibility_waitTimeInSecondsBetweenClaims() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 1, address(0), 0, proofs, 0);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 1, address(0), 0, proofs, 0);
    }

    function test_multiple_claim_exploit() public {
        MasterExploitContract masterExploit = new MasterExploitContract(address(drop));

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 1;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        bytes32[] memory proofs = new bytes32[](0);

        vm.startPrank(getActor(5));
        vm.expectRevert(bytes("BOT"));
        masterExploit.performExploit(
            address(masterExploit),
            conditions[0].quantityLimitPerTransaction,
            conditions[0].currency,
            conditions[0].pricePerToken,
            proofs,
            0
        );
    }

    /*///////////////////////////////////////////////////////////////
                                Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_revert_claim_claimQty(uint256 x) public {
        vm.assume(x != 0);
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, 200, address(0), 0, proofs, x);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("invalid quantity.");
        drop.claim(receiver, 200, address(0), 0, proofs, x);
    }

    function test_claimCondition_merkleProof(uint256 x) public {
        vm.assume(x != 0 && x < 500);
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = Strings.toString(x);

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);

        // bytes32[] memory proofs = new bytes32[](0);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;
        conditions[0].merkleRoot = root;

        vm.prank(deployer);
        drop.lazyMint(x, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, x, address(0), 0, proofs, x);

        vm.prank(address(4), address(4));
        vm.expectRevert("not in whitelist.");
        drop.claim(receiver, x, address(0), 0, proofs, x);
    }

    function testFail_claimCondition_merkleProof(uint256 x, uint256 y) public {
        vm.assume(x != 0 && x < 500);
        vm.assume(x != y);
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = Strings.toString(x);

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);

        // bytes32[] memory proofs = new bytes32[](0);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;
        conditions[0].merkleRoot = root;

        vm.prank(deployer);
        drop.lazyMint(x, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, x, address(0), 0, proofs, y);

        vm.prank(address(4), address(4));
        vm.expectRevert("not in whitelist.");
        drop.claim(receiver, x, address(0), 0, proofs, y);
    }
}
