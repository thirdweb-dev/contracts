# ERC20ForwardRequestTypes





This contract defines a struct which both ERC20FeeProxy and BiconomyForwarder inherit. ERC20ForwardRequest specifies all the fields present in the GSN V2 ForwardRequest struct,  but adds the following : address token uint256 tokenGasPrice uint256 txGas uint256 batchNonce (can be removed) uint256 deadline  Fields are placed in type order, to minimise storage used when executing transactions.





