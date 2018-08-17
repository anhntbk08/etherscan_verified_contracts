pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}

/**
 * @title IERC20Token - ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title ERC20Token - ERC20 base implementation
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Token is IERC20Token {

    using SafeMath for uint256;

    
    mapping (address =&gt; uint256) public balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] &gt;= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
      return allowed[_owner][_spender];
    }
}


contract JointToken is ERC20Token {

    uint256 public constant RewardPoolAmount = 500000000;
    uint256 public constant ICOInvestorsAmount = 100000000;
    uint256 public constant EarlyAdoptersAmount = 5000000;
    uint256 public constant LaunchPartnersAmount = 5000000;
    uint256 public constant TeamMembersAmount = 5000000;
    uint256 public constant MarketingDevelopmentAmount = 1000000;

    uint256 public constant EstimatedICOBonusAmount = 14000000;

    address public constant RewardPoolAddress = 0xEb1FAef9068b6B8f46b50245eE877dA5b03D98C9;
    address public constant ICOAddress = 0x29eC21157f19F7822432e87ef504D366c24E1D8B;
    address public constant EarlyAdoptersAddress = 0x5DD184EC1fB992c158EA15936e57A20C70761f84;
    address public constant LaunchPartnersAddress = 0x4A1943b2aB647a5150ECEc16D6Bf695f10D94E0E;
    address public constant TeamMembersAddress = 0x5a5b2715121e762B43D9A657E10AE93A5629Fe28;
    address public constant MarketingDevelopmentAddress = 0x5E1D0513Bc39fBD6ECd94447e627919Bbf575eC0;
    
    uint256 public  decimalPlace;


    function JointToken() public {
        name = &quot;JOINT&quot;;
        symbol = &quot;JOINT&quot;;
        decimals = 18;

        decimalPlace = 10**uint256(decimals);
        totalSupply = 616000000*decimalPlace;
        distributeTokens();
    }

    function distributeTokens () private {
        balances[RewardPoolAddress] = (RewardPoolAmount.sub(EstimatedICOBonusAmount)).mul(decimalPlace);
        balances[ICOAddress] = (ICOInvestorsAmount.add(EstimatedICOBonusAmount)).mul(decimalPlace);
        balances[EarlyAdoptersAddress] = EarlyAdoptersAmount.mul(decimalPlace);
        balances[LaunchPartnersAddress] = LaunchPartnersAmount.mul(decimalPlace);
        balances[TeamMembersAddress] = TeamMembersAmount.mul(decimalPlace);
        balances[MarketingDevelopmentAddress] = MarketingDevelopmentAmount.mul(decimalPlace);
    }

}