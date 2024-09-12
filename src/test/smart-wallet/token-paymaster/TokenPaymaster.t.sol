// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import "../../utils/BaseTest.sol";
import { MockERC20CustomDecimals } from "../../mocks/MockERC20CustomDecimals.sol";
import { TestUniswap } from "../../mocks/TestUniswap.sol";
import { TestOracle2 } from "../../mocks/TestOracle2.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/EntryPoint.sol";
import { PackedUserOperation } from "contracts/prebuilts/account/interfaces/PackedUserOperation.sol";

// Target
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Account as SimpleAccount } from "contracts/prebuilts/account/non-upgradeable/Account.sol";
import { TokenPaymaster, IERC20Metadata } from "contracts/prebuilts/account/token-paymaster/TokenPaymaster.sol";
import { OracleHelper, IOracle } from "contracts/prebuilts/account/utils/OracleHelper.sol";
import { UniswapHelper, ISwapRouter } from "contracts/prebuilts/account/utils/UniswapHelper.sol";

/// @dev This is a dummy contract to test contract interactions with Account.
contract Number {
    uint256 public num;

    function setNum(uint256 _num) public {
        num = _num;
    }

    function doubleNum() public {
        num *= 2;
    }

    function incrementNum() public {
        num += 1;
    }
}

contract TokenPaymasterTest is BaseTest {
    EntryPoint private entrypoint;
    AccountFactory private accountFactory;
    SimpleAccount private account;
    MockERC20CustomDecimals private token;
    TestUniswap private testUniswap;
    TestOracle2 private nativeAssetOracle;
    TestOracle2 private tokenOracle;
    TokenPaymaster private paymaster;

    Number private numberContract;

    int256 initialPriceToken = 100000000; // USD per TOK
    int256 initialPriceEther = 500000000; // USD per ETH

    uint256 priceDenominator = 10 ** 26;
    uint128 minEntryPointBalance = 1e17;

    address payable private beneficiary = payable(address(0x45654));

    uint256 private accountAdminPKey = 100;
    address private accountAdmin;

    uint256 private accountSignerPKey = 200;
    address private accountSigner;

    uint256 private nonSignerPKey = 300;
    address private nonSigner;

    uint256 private paymasterOwnerPKey = 400;
    address private paymasterOwner;
    address private paymasterAddress;

    function setUp() public override {
        super.setUp();

        // Setup signers.
        accountAdmin = vm.addr(accountAdminPKey);
        vm.deal(accountAdmin, 100 ether);

        accountSigner = vm.addr(accountSignerPKey);
        nonSigner = vm.addr(nonSignerPKey);
        paymasterOwner = vm.addr(paymasterOwnerPKey);

        // Setup contracts
        entrypoint = new EntryPoint();
        testUniswap = new TestUniswap(weth);
        accountFactory = new AccountFactory(deployer, IEntryPoint(payable(address(entrypoint))));
        account = SimpleAccount(payable(accountFactory.createAccount(accountAdmin, bytes(""))));
        token = new MockERC20CustomDecimals(6);
        nativeAssetOracle = new TestOracle2(initialPriceEther, 8);
        tokenOracle = new TestOracle2(initialPriceToken, 8);
        numberContract = new Number();

        weth.deposit{ value: 1 ether }();
        weth.transfer(address(testUniswap), 1 ether);

        TokenPaymaster.TokenPaymasterConfig memory tokenPaymasterConfig = TokenPaymaster.TokenPaymasterConfig({
            priceMarkup: (priceDenominator * 15) / 10, // +50%
            minEntryPointBalance: minEntryPointBalance,
            refundPostopCost: 40000,
            priceMaxAge: 86400
        });

        OracleHelper.OracleHelperConfig memory oracleHelperConfig = OracleHelper.OracleHelperConfig({
            cacheTimeToLive: 0,
            maxOracleRoundAge: 0,
            nativeOracle: IOracle(address(nativeAssetOracle)),
            nativeOracleReverse: false,
            priceUpdateThreshold: (priceDenominator * 12) / 100, // 20%
            tokenOracle: IOracle(address(tokenOracle)),
            tokenOracleReverse: false,
            tokenToNativeOracle: false
        });

        UniswapHelper.UniswapHelperConfig memory uniswapHelperConfig = UniswapHelper.UniswapHelperConfig({
            minSwapAmount: 1,
            slippage: 5,
            uniswapPoolFee: 3
        });

        paymaster = new TokenPaymaster(
            IERC20Metadata(address(token)),
            entrypoint,
            weth,
            ISwapRouter(address(testUniswap)),
            tokenPaymasterConfig,
            oracleHelperConfig,
            uniswapHelperConfig,
            paymasterOwner
        );
        paymasterAddress = address(paymaster);

        token.mint(paymasterOwner, 10_000 ether);
        vm.deal(paymasterOwner, 10_000 ether);

        vm.startPrank(paymasterOwner);
        token.transfer(address(paymaster), 100);
        paymaster.updateCachedPrice(true);
        entrypoint.depositTo{ value: 1000 ether }(address(paymaster));
        paymaster.addStake{ value: 2 ether }(1);
        vm.stopPrank();
    }

    // test utils
    function _packPaymasterStaticFields(
        address paymaster,
        uint128 validationGasLimit,
        uint128 postOpGasLimit
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes20(paymaster), bytes16(validationGasLimit), bytes16(postOpGasLimit));
    }

    function _setupUserOpWithSenderAndPaymaster(
        bytes memory _initCode,
        bytes memory _callDataForEntrypoint,
        address _sender,
        address _paymaster,
        uint128 _paymasterVerificationGasLimit,
        uint128 _paymasterPostOpGasLimit
    ) internal returns (PackedUserOperation[] memory ops) {
        uint256 nonce = entrypoint.getNonce(_sender, 0);
        PackedUserOperation memory op;

        {
            uint128 verificationGasLimit = 500_000;
            uint128 callGasLimit = 500_000;
            bytes32 packedAccountGasLimits = (bytes32(uint256(verificationGasLimit)) << 128) |
                bytes32(uint256(callGasLimit));
            bytes32 packedGasLimits = (bytes32(uint256(1e9)) << 128) | bytes32(uint256(1e9));

            // Get user op fields
            op = PackedUserOperation({
                sender: _sender,
                nonce: nonce,
                initCode: _initCode,
                callData: _callDataForEntrypoint,
                accountGasLimits: packedAccountGasLimits,
                preVerificationGas: 500_000,
                gasFees: packedGasLimits,
                paymasterAndData: _packPaymasterStaticFields(
                    _paymaster,
                    _paymasterVerificationGasLimit,
                    _paymasterPostOpGasLimit
                ),
                signature: bytes("")
            });
        }

        // Sign UserOp
        bytes32 opHash = EntryPoint(entrypoint).getUserOpHash(op);
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(opHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(accountAdminPKey, msgHash);
        bytes memory userOpSignature = abi.encodePacked(r, s, v);

        address recoveredSigner = ECDSA.recover(msgHash, v, r, s);
        address expectedSigner = vm.addr(accountAdminPKey);
        assertEq(recoveredSigner, expectedSigner);

        op.signature = userOpSignature;

        // Store UserOp
        ops = new PackedUserOperation[](1);
        ops[0] = op;
    }

    // Should be able to sponsor the UserOp while charging correct amount of ERC-20 tokens
    function test_validatePaymasterUserOp_correctERC20() public {
        token.mint(address(account), 1 ether);
        vm.prank(address(account));
        token.approve(address(paymaster), type(uint256).max);

        PackedUserOperation[] memory ops = _setupUserOpWithSenderAndPaymaster(
            bytes(""),
            abi.encodeWithSignature(
                "execute(address,uint256,bytes)",
                address(numberContract),
                0,
                abi.encodeWithSignature("setNum(uint256)", 42)
            ),
            address(account),
            address(paymaster),
            3e5,
            3e5
        );

        entrypoint.handleOps(ops, beneficiary);
    }
}
