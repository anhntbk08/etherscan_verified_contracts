pragma solidity ^0.4.11;

contract VKBToken {
	string public constant symbol = &quot;VKB&quot;;
	string public constant name = &quot;VKBToken&quot;;
	uint8 public constant decimals = 18;
	uint256 _totalSupply = 210000;
	
	address public owner;
	
	mapping(address =&gt; uint256) balances;
	
	mapping(address =&gt; mapping(address =&gt; uint256)) allowed;
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	modifier onlyOwner() {
	    require(msg.sender == owner);
	    _;
	}
	
	function VKBToken() {
	    owner = msg.sender;
	    balances[owner] = _totalSupply;
	}

	function totalSupply() constant returns (uint256 totalSupply) {
	    totalSupply = _totalSupply;
	}
	
	function balanceOf(address _owner) constant returns (uint256 balance) {
	    return balances[_owner];
	}
	
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] &gt;= _amount 
            &amp;&amp; _amount &gt; 0
            &amp;&amp; balances[_to] + _amount &gt; balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] &gt;= _amount
            &amp;&amp; allowed[_from][msg.sender] &gt;= _amount
            &amp;&amp; _amount &gt; 0
            &amp;&amp; balances[_to] + _amount &gt; balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}