// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {}

contract TokenERC1155Test_SetOwner is BaseTest {
    address public implementation;
    address public proxy;
    address internal caller;
    address internal _newOwner;

    MyTokenERC1155 internal tokenContract;

    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC1155());

        caller = getActor(1);
        _newOwner = getActor(2);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC1155.initialize,
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
        );

        tokenContract = MyTokenERC1155(proxy);
    }

    function test_setOwner_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );
        tokenContract.setOwner(_newOwner);
    }

    modifier whenCallerAuthorized() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), caller);
        _;
    }

    function test_setOwner_newOwnerNotAdmin() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectRevert("new owner not module admin.");
        tokenContract.setOwner(_newOwner);
    }

    modifier whenNewOwnerIsAnAdmin() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), _newOwner);
        _;
    }

    function test_setOwner() public whenCallerAuthorized whenNewOwnerIsAnAdmin {
        vm.prank(address(caller));
        tokenContract.setOwner(_newOwner);

        assertEq(tokenContract.owner(), _newOwner);
    }

    function test_setOwner_event() public whenCallerAuthorized whenNewOwnerIsAnAdmin {
        vm.prank(address(caller));
        vm.expectEmit(true, true, false, false);
        emit OwnerUpdated(deployer, _newOwner);
        tokenContract.setOwner(_newOwner);
    }
}
