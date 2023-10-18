// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ContractMetadata, IContractMetadata } from "contracts/extension/upgradeable/ContractMetadata.sol";
import "../../../ExtensionUtilTest.sol";

contract MyContractMetadataUpg is ContractMetadata {
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function _canSetContractURI() internal view override returns (bool) {
        return msg.sender == admin;
    }
}

contract UpgradeableContractMetadata_SetContractURI is ExtensionUtilTest {
    MyContractMetadataUpg internal ext;
    address internal admin;
    address internal caller;
    string internal uri;

    event ContractURIUpdated(string prevURI, string newURI);

    function setUp() public override {
        super.setUp();

        admin = getActor(0);
        caller = getActor(1);
        uri = "ipfs://newUri";

        ext = new MyContractMetadataUpg(address(admin));
    }

    function test_setContractURI_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert("Not authorized");
        ext.setContractURI(uri);
    }

    modifier whenCallerAuthorized() {
        caller = admin;
        _;
    }

    function test_setContractURI() public whenCallerAuthorized {
        vm.prank(address(caller));
        ext.setContractURI(uri);

        string memory _updatedUri = ext.contractURI();
        assertEq(_updatedUri, uri);
    }

    function test_setContractURI_event() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectEmit(false, false, false, true);
        emit ContractURIUpdated("", uri);
        ext.setContractURI(uri);
    }
}
