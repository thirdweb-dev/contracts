// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { LazyMint, BatchMintMetadata } from "contracts/extension/LazyMint.sol";
import "../../ExtensionUtilTest.sol";

contract MyLazyMint is LazyMint {
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function _canLazyMint() internal view override returns (bool) {
        return msg.sender == admin;
    }

    function getBaseURI(uint256 _tokenId) external view returns (string memory) {
        return _getBaseURI(_tokenId);
    }

    function getBatchStartId(uint256 _batchID) public view returns (uint256) {
        return _getBatchStartId(_batchID);
    }

    function nextTokenIdToMint() public view returns (uint256) {
        return nextTokenIdToLazyMint;
    }
}

contract LazyMint_LazyMint is ExtensionUtilTest {
    MyLazyMint internal ext;
    uint256 internal startId;
    uint256 internal amount;
    uint256[] internal batchIds;
    address internal admin;
    address internal caller;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);

    function setUp() public override {
        super.setUp();

        admin = getActor(0);
        caller = getActor(1);

        ext = new MyLazyMint(address(admin));

        startId = 0;
        // mint 5 batches
        vm.startPrank(admin);
        for (uint256 i = 0; i < 5; i++) {
            uint256 _amount = (i + 1) * 10;
            uint256 batchId = startId + _amount;
            batchIds.push(batchId);

            string memory baseURI = Strings.toString(batchId);
            startId = ext.lazyMint(_amount, baseURI, "");
        }
        vm.stopPrank();
    }

    function test_lazyMint_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(abi.encodeWithSelector(LazyMint.LazyMintUnauthorized.selector));
        ext.lazyMint(amount, "", "");
    }

    modifier whenCallerAuthorized() {
        caller = admin;
        _;
    }

    function test_lazyMint_zeroAmount() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectRevert(abi.encodeWithSelector(LazyMint.LazyMintInvalidAmount.selector));
        ext.lazyMint(amount, "", "");
    }

    modifier whenAmountNotZero() {
        amount = 50;
        _;
    }

    function test_lazyMint() public whenCallerAuthorized whenAmountNotZero {
        // check previous state
        uint256 _nextTokenIdToLazyMintOld = ext.nextTokenIdToMint();
        assertEq(_nextTokenIdToLazyMintOld, batchIds[4]);

        string memory baseURI = "ipfs://baseURI";

        // lazy mint next batch
        vm.prank(address(caller));
        uint256 _batchId = ext.lazyMint(amount, baseURI, "");

        // check new state
        uint256 _batchStartId = ext.getBatchStartId(_batchId);
        assertEq(_nextTokenIdToLazyMintOld, _batchStartId);
        assertEq(_batchId, _nextTokenIdToLazyMintOld + amount);
        for (uint256 i = _batchStartId; i < _batchId; i++) {
            assertEq(ext.getBaseURI(i), baseURI);
        }
        assertEq(ext.nextTokenIdToMint(), _nextTokenIdToLazyMintOld + amount);
    }

    function test_lazyMint_event() public whenCallerAuthorized whenAmountNotZero {
        string memory baseURI = "ipfs://baseURI";
        uint256 _nextTokenIdToLazyMintOld = ext.nextTokenIdToMint();

        // lazy mint next batch
        vm.prank(address(caller));
        vm.expectEmit();
        emit TokensLazyMinted(_nextTokenIdToLazyMintOld, _nextTokenIdToLazyMintOld + amount - 1, baseURI, "");
        ext.lazyMint(amount, baseURI, "");
    }
}
