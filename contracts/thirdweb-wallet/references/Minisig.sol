pragma solidity 0.6.6;

// The point of this contract is to provide an executable solidity reference
// implementation that will approximate the huff implementation. The result
// is exceptionally bad solidity, and this should not be used except for
// comparison with huff impl. It will also not match the huff particularly
// well, because the huff uses an approach that can't be built in solidity.
contract Minisig {
    // --- Data structures ---
    enum CallType {
        Call,
        DelegateCall
    }

    // --- State ---
    uint256 private _nonce;

    // --- Immutables and constants ---
    address[] private signers; // approved signers, immutable in huff impl.
    uint8 private immutable threshold; // minimum required signers

    // EIP712 stuff
    bytes32 private immutable DOMAIN_SEPARATOR;
    // keccak256("EIP712Domain(uint256 chainId,uint256 deployBlock,address verifyingContract)");
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        0x0a684fcd4736a0673611bfe1e61ceb93fb09bcd288bc72c1155ebe13280ffeca;
    // TODO: update exec typehash
    // keccak256("Execute(address target,uint8 callType,uint256 nonce,uint256 txGas,uint256 value,bytes data)");
    bytes32 private constant EXECUTE_TYPEHASH = 0x9c1370cbf5462da152553d1b9556f96a7eb4dfe28fbe07e763227834d409103a;

    // --- Fallback function ---
    receive() external payable {} // recieve ether only if calldata is empty

    // --- Constructor ---
    constructor(uint8 _threshold, address[] memory _signers) public payable {
        require(_signers.length >= _threshold, "signers-invalid-length");

        // set domain separator for EIP712 signatures
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, block.number, address(this)));

        // signers must be ascending order, and cannot be 0
        address prevSigner;
        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] > prevSigner, "invalid-signer");
            prevSigner = _signers[i];
        }

        // set threshold and valid signers
        threshold = _threshold;
        signers = _signers;
    }

    function execute(
        address _source,
        address _target,
        CallType _callType,
        uint256 _txGas,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _sigs
    ) external payable {
        require(_source == address(0) || _source == msg.sender, "invalid-caller");
        // must submit enough signatures to satisfy threshold
        // max(uint8) * 65 << max(uint256), so no overflow check
        require(_sigs.length >= uint256(threshold) * 65, "sigs-invalid-length");

        // update nonce
        uint256 origNonce = _nonce;
        uint256 newNonce = origNonce + 1;
        _nonce = newNonce;

        // signed message hash
        bytes32 digest = keccak256(
            abi.encodePacked(
                // byte(0x19), byte(0x01)
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        EXECUTE_TYPEHASH,
                        _source,
                        _target,
                        _callType,
                        origNonce,
                        _txGas,
                        _value,
                        keccak256(_data)
                    )
                )
            )
        );

        // check signature validity
        // Note: a single invalid sig will cause a revert, even if there are
        // `>= threshold` valid sigs. But, an invalid sig after `threshold`
        // valid sigs is ignored
        uint256 signerIdx = 0;
        for (uint256 i = 0; i < threshold; i++) {
            // sig should be 65 bytes total, {32 byte r}{32 byte s}{1 byte v}
            uint256 sigIdx = 65 * i;
            bytes32 r = abi.decode(_sigs[sigIdx:sigIdx + 32], (bytes32));
            bytes32 s = abi.decode(_sigs[sigIdx + 32:sigIdx + 64], (bytes32));
            uint8 v = uint8(_sigs[sigIdx + 64]);
            address addr = ecrecover(digest, v, r, s);

            // for current signerIdx to end of signers, check each signer against
            // recovered address.
            // If we exhaust the list without a match, revert
            // if we find a match, signerIdx = match index, continue looping through sigs
            bool elem = false;
            for (uint256 j = signerIdx; j < signers.length && !elem; j++) {
                if (addr == signers[j]) {
                    elem = true;
                    signerIdx = j + 1;
                    // break
                }
            }
            require(elem, "not-signer");
        }

        // make call dependent on callType
        bool success;
        if (_callType == CallType.Call) {
            (success, ) = _target.call{ value: _value, gas: _txGas }(_data);
        } else if (_callType == CallType.DelegateCall) {
            (success, ) = _target.delegatecall{ gas: _txGas }(_data);
        }

        // check call succeeded
        require(success, "call-failure");
    }

    // --- Nonce getter ---
    function nonce() external view returns (uint256) {
        return _nonce;
    }

    // --- Solidity-specific getters ---
    // These getters are specific to the solidity implementation. In the huff
    // implementation, this data is available on-chain via `codecopy()`
    function getAllSigners() external view returns (address[] memory) {
        return signers;
    }

    function getDOMAIN_SEPARATOR() external view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    function getThreshold() external view returns (uint256) {
        return threshold;
    }
}
