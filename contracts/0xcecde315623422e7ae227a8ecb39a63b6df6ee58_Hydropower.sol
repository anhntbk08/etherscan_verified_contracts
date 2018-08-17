pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b &lt;= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title StakeStandard
 * @dev the interface of StakeStandard
 */
contract StakeStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mine() returns (bool);
    function coinAge() constant returns (uint256);
    function annualInterest() constant returns (uint256);
    event Mine(address indexed _address, uint _reward);
}


contract Hydropower is ERC20,StakeStandard,Ownable {
    using SafeMath for uint256;

    string public name = &quot;Hydro Power&quot;;
    string public symbol = &quot;HYP&quot;;
    uint public decimals = 18;

    uint public chainStartTime;
    uint public chainStartBlockNumber;
    uint public stakeStartTime;
    uint public stakeMinAge = 1 days;
    uint public stakeMaxAge = 90 days;
    uint public maxMintProofOfStake = 5 * (10**17); //50%
	uint public mintBase = 10**17; //10%

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    struct transferInStruct{
    uint128 amount;
    uint64 time;
    }

    mapping(address =&gt; uint256) balances;
    mapping(address =&gt; mapping (address =&gt; uint256)) allowed;
    mapping(address =&gt; transferInStruct[]) transferIns;

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length &gt;= size + 4);
        _;
    }

    modifier canPoSMint() {
        require(totalSupply &lt; maxTotalSupply);
        _;
    }

    function Hydropower() {
        maxTotalSupply = 10**25; // 10 Mil.
        totalInitialSupply = 2.5*(10**23); // 1 Mil.

        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
        if(msg.sender == _to) return mine();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        if(transferIns[msg.sender].length &gt; 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        if(transferIns[_from].length &gt; 0) delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mine() canPoSMint returns (bool) {
        if(balances[msg.sender] &lt;= 0) return false;
        if(transferIns[msg.sender].length &lt;= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward &lt;= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        Mine(msg.sender, reward);
        return true;
    }

    function getBlockNumber() returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() constant returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() constant returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            interest = 6 * (770 * mintBase).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            interest = 6 * (435 * mintBase).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal returns (uint) {
        require( (now &gt;= stakeStartTime) &amp;&amp; (stakeStartTime &gt; 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge &lt;= 0) return 0;

        uint interest = maxMintProofOfStake;
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 600% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = 6 * (770 * mintBase).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            // 2nd year effective annual interest rate is 300%
            interest = 6 * (435 * mintBase).div(100);
        }

        return (_coinAge * interest).div(365 * (10**decimals));
    }

    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if(transferIns[_address].length &lt;= 0) return 0;

        for (uint i = 0; i &lt; transferIns[_address].length; i++){
            if( _now &lt; uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds &gt; stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function ownerSetStakeStartTime(uint timestamp) onlyOwner {
        require((stakeStartTime &lt;= 0) &amp;&amp; (timestamp &gt;= chainStartTime));
        stakeStartTime = timestamp;
    }

    function ownerBurnToken(uint _value) onlyOwner {
        require(_value &gt; 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        maxTotalSupply = maxTotalSupply.sub(_value*10);

        Burn(msg.sender, _value);
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner returns (bool) {
        require( _recipients.length &gt; 0 &amp;&amp; _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i &lt; _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total &lt;= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j &lt; _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(transferIns[msg.sender].length &gt; 0) delete transferIns[msg.sender];
        if(balances[msg.sender] &gt; 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }
	
	function mintToken(address target, uint256 mintedAmount) onlyOwner {
		balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
	
	function Destroy() onlyOwner() {
        selfdestruct(owner);
    }
}