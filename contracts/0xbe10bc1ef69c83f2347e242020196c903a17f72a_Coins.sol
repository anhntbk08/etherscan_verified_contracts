pragma solidity ^0.4.8;
contract ERC20Interface {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Coins is ERC20Interface {
    string public name;
    uint8 public decimals;
    string public symbol;
	address public owner;
    mapping(address =&gt; mapping (address =&gt; uint256)) allowed;
    mapping(address =&gt; uint256) balances;
	uint256 _totalSupply;
    function Coins() { owner = msg.sender; name = &quot;24Coins&quot;; symbol = &quot;24COINS&quot;; decimals = 8; _totalSupply = 1000000000000000; balances[owner] = _totalSupply; }
    function balanceOf(address _owner) constant returns (uint256 balance) { return balances[_owner]; }
    function totalSupply() constant returns (uint256 totalSupply) { totalSupply = _totalSupply; }
	function transfer(address _to, uint256 _amount) returns (bool success) { if (balances[msg.sender] &gt;= _amount &amp;&amp; _amount &gt; 0) { balances[msg.sender] -= _amount; balances[_to] += _amount; Transfer(msg.sender, _to, _amount); return true; } else { return false; } }
	modifier onlyOwner() { if (msg.sender != owner) { throw; } _; }
	function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) { if (balances[_from] &gt;= _amount &amp;&amp; allowed[_from][msg.sender] &gt;= _amount &amp;&amp; _amount &gt; 0) { balances[_to] += _amount; balances[_from] -= _amount; allowed[_from][msg.sender] -= _amount; Transfer(_from, _to, _amount); return true; } else { return false; } }
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) { return allowed[_owner][_spender]; }
    function approve(address _spender, uint256 _amount) returns (bool success) { allowed[msg.sender][_spender] = _amount; Approval(msg.sender, _spender, _amount); return true; }
	function () { throw; }
}