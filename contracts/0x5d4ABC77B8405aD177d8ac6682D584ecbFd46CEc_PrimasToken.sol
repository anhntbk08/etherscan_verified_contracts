pragma solidity ^0.4.23;

library Roles {
    struct Role {
        mapping(address =&gt; bool) bearer;
    }

    function add(Role storage role, address addr) internal {
        role.bearer[addr] = true;
    }

    function remove(Role storage role, address addr) internal {
        role.bearer[addr] = false;
    }

    function check(Role storage role, address addr) view internal {
        require(has(role, addr));
    }

    function has(Role storage role, address addr) view internal returns (bool) {
        return role.bearer[addr];
    }
}

contract RBAC {

    address initialOwner;

    using Roles for Roles.Role;

    mapping(string =&gt; Roles.Role) private roles;

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);

    modifier onlyOwner() {
        require(msg.sender == initialOwner);
        _;
    }

    function checkRole(address addr, string roleName) view public {
        roles[roleName].check(addr);
    }

    function hasRole(address addr, string roleName) view public returns (bool) {
        return roles[roleName].has(addr);
    }

    function addRole(address addr, string roleName) public onlyOwner {
        roles[roleName].add(addr);
        emit RoleAdded(addr, roleName);
    }

    function removeRole(address addr, string roleName) public onlyOwner {
        roles[roleName].remove(addr);
        emit RoleRemoved(addr, roleName);
    }

    modifier onlyRole(string roleName) {
        checkRole(msg.sender, roleName);
        _;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b &gt; 0);
        // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        assert(b &lt;= a);
        assert(a == c + b);
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a);
        assert(a == c - b);
        return c;
    }
}

contract PrimasToken is RBAC {

    using SafeMath for uint256;

    string public name;
    uint256 public decimals;
    string public symbol;
    string public version;
    uint256 public totalSupply;
    uint256 initialAmount;
    uint256 deployTime;
    uint256 lastInflationDayStart;
    uint256 incentivesPool;

    mapping(address =&gt; uint256) private userLockedTokens;
    mapping(address =&gt; uint256) balances;
    mapping(address =&gt; mapping(address =&gt; uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Lock(address userAddress, uint256 amount);
    event Unlock(address userAddress,uint256 amount);
    event Inflate (uint256 incentivesPoolValue);

    constructor(uint256 _previouslyInflatedAmount) public {
        name = &quot;Primas Token&quot;;
        decimals = 18;
        symbol = &quot;PST&quot;;
        version = &quot;V2.0&quot;;
        initialAmount = 100000000 * 10 ** decimals;
        initialOwner = msg.sender;
        deployTime = block.timestamp;
        lastInflationDayStart = 0;
        incentivesPool = 0;

        // Primas token is deployed at 2018/06/01
        // When upgrading after new deployment of the contract
        // we need to add the inflated tokens back
        // for system consistency.

        totalSupply = initialAmount.add(_previouslyInflatedAmount);
        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function inflate() public onlyRole(&quot;InflationOperator&quot;) returns (uint256)  {
        uint256 currentTime = block.timestamp;
        uint256 currentDayStart = currentTime / 1 days;
        uint256 inflationAmount;
        require(lastInflationDayStart != currentDayStart);
        lastInflationDayStart = currentDayStart;
        uint256 createDurationYears = (currentTime - deployTime) / 1 years;
        if (createDurationYears &lt; 1) {
            inflationAmount = initialAmount / 10 / 365;
        } else if (createDurationYears &gt;= 20) {
            inflationAmount = 0;
        } else {
            inflationAmount = initialAmount * (100 - (5 * createDurationYears)) / 365 / 1000;
        }
        incentivesPool = incentivesPool.add(inflationAmount);
        totalSupply = totalSupply.add(inflationAmount);
        emit Inflate(incentivesPool);
        return incentivesPool;
    }

    function getIncentivesPool() view public returns (uint256) {
        return incentivesPool;
    }

    function incentivesIn(address[] _users, uint256[] _values) public onlyRole(&quot;IncentivesCollector&quot;) returns (bool success) {
        require(_users.length == _values.length);
        for (uint256 i = 0; i &lt; _users.length; i++) {
            userLockedTokens[_users[i]] = userLockedTokens[_users[i]].sub(_values[i]);
            balances[_users[i]] = balances[_users[i]].sub(_values[i]);
            incentivesPool = incentivesPool.add(_values[i]);
            emit Transfer(_users[i], address(0), _values[i]);
        }
        return true;
    }

    function incentivesOut(address[] _users, uint256[] _values) public onlyRole(&quot;IncentivesDistributor&quot;) returns (bool success) {
        require(_users.length == _values.length);
        for (uint256 i = 0; i &lt; _users.length; i++) {
            incentivesPool = incentivesPool.sub(_values[i]);
            balances[_users[i]] = balances[_users[i]].add(_values[i]);
            emit Transfer(address(0), _users[i], _values[i]);
        }
        return true;
    }

    function tokenLock(address _userAddress, uint256 _amount) public onlyRole(&quot;Locker&quot;) {
        require(balanceOf(_userAddress) &gt;= _amount);
        userLockedTokens[_userAddress] = userLockedTokens[_userAddress].add(_amount);
        emit Lock(_userAddress, _amount);
    }

    function tokenUnlock(address _userAddress, uint256 _amount, address _to, uint256 _toAmount) public onlyRole(&quot;Unlocker&quot;) {
        require(_amount &gt;= _toAmount);
        require(userLockedTokens[_userAddress] &gt;= _amount);
        userLockedTokens[_userAddress] = userLockedTokens[_userAddress].sub(_amount);
        emit Unlock(_userAddress, _amount);
        if (_to != address(0) &amp;&amp; _toAmount != 0) {
            balances[_userAddress] = balances[_userAddress].sub(_toAmount);
            balances[_to] = balances[_to].add(_toAmount);
            emit Transfer(_userAddress, _to, _toAmount);
        }
    }

    function transferAndLock(address _userAddress, address _to, uint256 _amount) public onlyRole(&quot;Locker&quot;)  {
        require(balanceOf(_userAddress) &gt;= _amount);
        balances[_userAddress] = balances[_userAddress].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        userLockedTokens[_to] = userLockedTokens[_to].add(_amount);
        emit Transfer(_userAddress, _to, _amount);
        emit Lock(_to, _amount);
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner] - userLockedTokens[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) &gt;= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(_from) &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}