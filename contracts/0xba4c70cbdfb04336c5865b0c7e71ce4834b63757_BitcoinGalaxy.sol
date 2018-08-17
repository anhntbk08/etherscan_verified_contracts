pragma solidity ^0.4.18;

contract BitcoinGalaxy {
    string public symbol = &quot;BTCG&quot;;
    string public name = &quot;BitcoinGalaxy&quot;;
    uint8 public constant decimals = 8;
    uint256 _totalSupply = 0;
	uint256 _maxTotalSupply = 2100000000000000;
	uint256 _miningReward = 10000000000; //1 BTCG - To be halved every 4 years
	uint256 _maxMiningReward = 1000000000000; //50 BTCG - To be halved every 4 years
	uint256 _rewardHalvingTimePeriod = 126227704; //4 years
	uint256 _nextRewardHalving = now + _rewardHalvingTimePeriod;
	uint256 _rewardTimePeriod = 600; //10 minutes
	uint256 _rewardStart = now;
	uint256 _rewardEnd = now + _rewardTimePeriod;
	uint256 _currentMined = 0;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address =&gt; uint256) balances;
 
    mapping(address =&gt; mapping (address =&gt; uint256)) allowed;
 
    function totalSupply() public constant returns (uint256) {        
		return _totalSupply;
    }
 
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint256 _amount) public returns (bool success) {
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
    ) public returns (bool success) {
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
 
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	function Mine() public returns (bool success)
	{
		if (now &lt; _rewardEnd &amp;&amp; _currentMined &gt;= _maxMiningReward)
			revert();
		else if (now &gt;= _rewardEnd)
		{
			_rewardStart = now;
			_rewardEnd = now + _rewardTimePeriod;
			_currentMined = 0;
		}
	
		if (now &gt;= _nextRewardHalving)
		{
			_nextRewardHalving = now + _rewardHalvingTimePeriod;
			_miningReward = _miningReward / 2;
			_maxMiningReward = _maxMiningReward / 2;
			_currentMined = 0;
			_rewardStart = now;
			_rewardEnd = now + _rewardTimePeriod;
		}	
		
		if ((_currentMined &lt; _maxMiningReward) &amp;&amp; (_totalSupply &lt; _maxTotalSupply))
		{
			balances[msg.sender] += _miningReward;
			_currentMined += _miningReward;
			_totalSupply += _miningReward;
			Transfer(this, msg.sender, _miningReward);
			return true;
		}				
		return false;
	}
	
	function MaxTotalSupply() public constant returns(uint256)
	{
		return _maxTotalSupply;
	}
	
	function MiningReward() public constant returns(uint256)
	{
		return _miningReward;
	}
	
	function MaxMiningReward() public constant returns(uint256)
	{
		return _maxMiningReward;
	}
	
	function RewardHalvingTimePeriod() public constant returns(uint256)
	{
		return _rewardHalvingTimePeriod;
	}
	
	function NextRewardHalving() public constant returns(uint256)
	{
		return _nextRewardHalving;
	}
	
	function RewardTimePeriod() public constant returns(uint256)
	{
		return _rewardTimePeriod;
	}
	
	function RewardStart() public constant returns(uint256)
	{
		return _rewardStart;
	}
	
	function RewardEnd() public constant returns(uint256)
	{
		return _rewardEnd;
	}
	
	function CurrentMined() public constant returns(uint256)
	{
		return _currentMined;
	}
	
	function TimeNow() public constant returns(uint256)
	{
		return now;
	}
}