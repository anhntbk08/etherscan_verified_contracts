pragma solidity ^ 0.4 .18;

library SafeMath {
	function add(uint a, uint b) internal pure returns(uint c) {
		c = a + b;
		require(c &gt;= a);
	}

	function sub(uint a, uint b) internal pure returns(uint c) {
		require(b &lt;= a);
		c = a - b;
	}

	function mul(uint a, uint b) internal pure returns(uint c) {
		c = a * b;
		require(a == 0 || c / a == b);
	}

	function div(uint a, uint b) internal pure returns(uint c) {
		require(b &gt; 0);
		c = a / b;
	}
}

contract ERC20Interface {
	function totalSupply() public constant returns(uint);

	function balanceOf(address tokenOwner) public constant returns(uint balance);

	function allowance(address tokenOwner, address spender) public constant returns(uint remaining);

	function transfer(address to, uint tokens) public returns(bool success);

	function approve(address spender, uint tokens) public returns(bool success);

	function transferFrom(address from, address to, uint tokens) public returns(bool success);

	function burn(uint256 value) public returns(bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event Burn(address indexed from, uint256 value);
}

contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	function Owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner);
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

contract eSportsToken is ERC20Interface, Owned {
	using SafeMath
	for uint;
	string public symbol;
	string public name;
	uint8 public decimals;
	uint public _totalSupply;
	mapping(address =&gt; uint) balances;
	mapping(address =&gt; mapping(address =&gt; uint)) allowed;

	function eSportsToken() public {
		symbol = &quot;ESPT&quot;;
		name = &quot;eSports&quot;;
		decimals = 18;
		_totalSupply = 1500000000 * 10 ** uint(decimals);
		balances[owner] = _totalSupply;
		Transfer(address(0), owner, _totalSupply);
	}

	function totalSupply() public constant returns(uint) {
		return _totalSupply - balances[address(0)];
	}

	function balanceOf(address tokenOwner) public constant returns(uint balance) {
		return balances[tokenOwner];
	}

	function transfer(address to, uint tokens) public returns(bool success) {
		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		Transfer(msg.sender, to, tokens);
		return true;
	}

	function approve(address spender, uint tokens) public returns(bool success) {
		allowed[msg.sender][spender] = tokens;
		Approval(msg.sender, spender, tokens);
		return true;
	}

	function transferFrom(address from, address to, uint tokens) public returns(bool success) {
		balances[from] = balances[from].sub(tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);
		Transfer(from, to, tokens);
		return true;
	}

	function burn(uint256 value) public returns(bool success) {
		require(balances[msg.sender] &gt;= value);
		balances[msg.sender] -= value;
		_totalSupply -= value;
		Burn(msg.sender, value);
		return true;
	}

	function allowance(address tokenOwner, address spender) public constant returns(uint remaining) {
		return allowed[tokenOwner][spender];
	}

	function approveAndCall(address spender, uint tokens, bytes data) public returns(bool success) {
		allowed[msg.sender][spender] = tokens;
		Approval(msg.sender, spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
		return true;
	}

	function() public payable {
		revert();
	}

	function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool success) {
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}
}