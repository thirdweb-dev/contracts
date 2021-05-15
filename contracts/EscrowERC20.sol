pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract EscrowERC20 is Ownable {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  event Deposited(address indexed payee, address token, uint256 amount);
  event Withdrawn(address indexed payee, address token, uint256 amount);
  event WithdrawnBatch(address indexed payee, address[] tokens, uint256[] amounts);

  // owner -> erc20 address -> amount
  mapping(address => mapping(address => uint256)) private _deposits;

  // owner -> erc20 addresses
  mapping(address => EnumerableSet.AddressSet) _tokens;

  constructor() {
  }

  function balanceOf(address payee, address token) public view returns (uint256) {
    return _deposits[payee][token];
  }

  function tokens(address payee) public view returns (address[] memory) {
    address[] memory tokensArr = new address[](_tokens[payee].length());
    for (uint256 i = 0; i < tokens.length; i++) {
      tokensArr[i] = _tokens[payee].at(i);
    }
    return tokensArr;
  }

  function deposit(address payee, address token, uint256 amount) public onlyOwner {
    _deposits[payee][token] = _deposits[payee][token].add(amount);
    _tokens[payee].add(token);

    emit Deposited(payee, token, amount);
  }

  function withdraw(address payee, address token) public onlyOwner {
    uint256 withdrawAmount = _deposits[payee][token];
    require(withdrawAmount > 0, "insufficient balance");

    _deposits[payee][token] = 0;
    _tokens[payee].remove(token);

    IERC20(token).approve(address(this), withdrawAmount);
    IERC20(token).transferFrom(address(this), payee, withdrawAmount);

    emit Withdrawn(payee, token, withdrawAmount);
  }

  fallback() external payable {}
  receive() external payable {}
}
