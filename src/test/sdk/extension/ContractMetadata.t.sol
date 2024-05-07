// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ContractMetadata } from "contracts/extension/ContractMetadata.sol";

contract MyContractMetadata is ContractMetadata {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetContractURI() internal view override returns (bool) {
        return condition;
    }
}

contract ExtensionContractMetadataTest is DSTest, Test {
    MyContractMetadata internal ext;
    event ContractURIUpdated(string prevURI, string newURI);

    function setUp() public {
        ext = new MyContractMetadata();
    }

    function test_state_setContractURI() public {
        ext.setCondition(true);

        string memory uri = "uri_string";
        ext.setContractURI(uri);

        string memory contractURI = ext.contractURI();

        assertEq(contractURI, uri);
    }

    function test_revert_setContractURI() public {
        vm.expectRevert(abi.encodeWithSelector(ContractMetadata.ContractMetadataUnauthorized.selector));
        ext.setContractURI("");
    }

    function test_event_setContractURI() public {
        ext.setCondition(true);
        string memory uri = "uri_string";

        vm.expectEmit(true, true, true, true);
        emit ContractURIUpdated("", uri);

        ext.setContractURI(uri);
    }
}
