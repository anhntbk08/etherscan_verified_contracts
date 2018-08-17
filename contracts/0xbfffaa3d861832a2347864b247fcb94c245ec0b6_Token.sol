pragma solidity ^0.4.15;

contract owned 
{
	address public owner;

	function owned() public
	{
		owner = msg.sender;
	}

	function changeOwner(address newOwner) public onlyOwner 
	{
		owner = newOwner;
	}

	modifier onlyOwner 
	{
		require(msg.sender == owner);
		_;
	}
}

contract ERC20 {
	function totalSupply() public constant returns (uint totalTokenCount);
	function balanceOf(address _owner) public constant returns (uint balance);
	function transfer(address _to, uint _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	function approve(address _spender, uint _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}



contract Token is ERC20, owned 
{
	string public constant symbol = &quot;GMBC&quot;;
	string public constant name = &quot;GMBC&quot;;
	uint8 public constant decimals = 18;

	uint256 _totalSupply = 0;
	
	event Burned(address backer, uint _value);
 
	// Balances for each account
	mapping(address =&gt; uint256) balances;

	mapping(address =&gt; uint256) lockedTillTime;
 
	// Owner of account approves the transfer of an amount to another account
	mapping(address =&gt; mapping (address =&gt; uint256)) allowed;

	address public crowdsale;

	function changeCrowdsale(address newCrowdsale) public onlyOwner 
	{
		crowdsale = newCrowdsale;
	}

	modifier onlyOwnerOrCrowdsale 
	{
		require(msg.sender == owner || msg.sender == crowdsale);
		_;
	}

	function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) 
	{
		uint256 z = _x + _y;
		assert(z &gt;= _x);
		return z;
	}

	function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) 
	{
		assert(_x &gt;= _y);
		return _x - _y;
	}
	
	function totalSupply() public constant returns (uint256 totalTokenCount) 
	{
		return _totalSupply;
	}
 
	// What is the balance of a particular account?
	function balanceOf(address _owner) public constant returns (uint256 balance) 
	{
		return balances[_owner];
	}

	function getUnlockTime(address _owner) public constant returns (uint256 unlockTime) 
	{
		return lockedTillTime[_owner];
	}

	function isUnlocked(address _owner) public constant returns (bool unlocked) 
	{
		return lockedTillTime[_owner] &lt; now;
	}
 
	// Transfer the balance from owner&#39;s account to another account
	function transfer(address _to, uint256 _amount) public returns (bool success) 
	{
		if (balances[msg.sender] &gt;= _amount 
			&amp;&amp; _amount &gt; 0
			&amp;&amp; balances[_to] + _amount &gt; balances[_to]
			&amp;&amp; isUnlocked(msg.sender)) 
		{
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
		} else {
			revert();
		}
	}
 
	// Send _value amount of tokens from address _from to address _to
	// The transferFrom method is used for a withdraw workflow, allowing contracts to send
	// tokens on your behalf, for example to &quot;deposit&quot; to a contract address and/or to charge
	// fees in sub-currencies; the command should fail unless the _from account has
	// deliberately authorized the sender of the message via some mechanism; we propose
	// these standardized APIs for approval:
	function transferFrom(
		address _from,
		address _to,
		uint256 _amount
	) public returns (bool success) 
	{
		if (balances[_from] &gt;= _amount
			&amp;&amp; allowed[_from][msg.sender] &gt;= _amount
			&amp;&amp; _amount &gt; 0
			&amp;&amp; balances[_to] + _amount &gt; balances[_to] 
			&amp;&amp; isUnlocked(_from))
		{
			balances[_from] -= _amount;
			allowed[_from][msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(_from, _to, _amount);
			return true;
		} else {
			revert();
		}
	}
 
	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	function approve(address _spender, uint256 _amount) public returns (bool success) 
	{
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}
 
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
	{
		return allowed[_owner][_spender];
	}

	function mint(address target, uint256 mintedAmount, uint256 lockTime) public onlyOwnerOrCrowdsale 
	{
		require(mintedAmount &gt; 0);

		balances[target] = safeAdd(balances[target], mintedAmount);
		_totalSupply = safeAdd(_totalSupply, mintedAmount);

		if (lockedTillTime[target] &lt; lockTime)
		{
			lockedTillTime[target] = lockTime;
		}
	}

	function burn(address target, uint256 burnedAmount) public onlyOwnerOrCrowdsale
	{
		require(burnedAmount &gt; 0);

		if (balances[target] &gt;= burnedAmount)
		{
			balances[target] -= burnedAmount;
		}
		else
		{
			burnedAmount = balances[target];
			balances[target] = 0;
		}

		_totalSupply = safeSub(_totalSupply, burnedAmount);
		Burned(target, burnedAmount);
	}
}