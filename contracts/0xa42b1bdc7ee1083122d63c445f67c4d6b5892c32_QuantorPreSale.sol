pragma solidity ^0.4.18;

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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by requiring a state.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted = false;

  modifier inNormalState {
    require(!halted);
    _;
  }

  modifier inEmergencyState {
    require(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner inNormalState {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner inEmergencyState {
    halted = false;
  }
}

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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address =&gt; uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address =&gt; mapping (address =&gt; uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value &lt;= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Burnable
 *
 * @dev Standard ERC20 token
 */
contract Burnable is StandardToken {
  using SafeMath for uint;

  /* This notifies clients about the amount burnt */
  event Burn(address indexed from, uint value);

  function burn(uint _value) returns (bool success) {
    require(_value &gt; 0 &amp;&amp; balances[msg.sender] &gt;= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint _value) returns (bool success) {
    require(_from != 0x0 &amp;&amp; _value &gt; 0 &amp;&amp; balances[_from] &gt;= _value);
    require(_value &lt;= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Burn(_from, _value);
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    require(_to != 0x0); //use burn

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    require(_to != 0x0); //use burn

    return super.transferFrom(_from, _to, _value);
  }
}

/**
 * @title QuantorToken
 *
 * @dev Burnable Ownable ERC20 token
 */
contract QuantorToken is Burnable, Ownable {

  string public constant name = &quot;Quant&quot;;
  string public constant symbol = &quot;QNT&quot;;
  uint8 public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 2000000000 * 1 ether;

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address =&gt; bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

  /** The function can be called only before or after the tokens have been released */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }


  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function QuantorToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }


  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  function release() onlyReleaseAgent inReleaseState(false) public {
    released = true;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);
    transferAgents[addr] = state;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call Burnable.transfer()
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call Burnable.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

  function burn(uint _value) onlyOwner returns (bool success) {
    return super.burn(_value);
  }

  function burnFrom(address _from, uint _value) onlyOwner returns (bool success) {
    return super.burnFrom(_from, _value);
  }
}

contract InvestorWhiteList is Ownable {
  mapping (address =&gt; bool) public investorWhiteList;

  mapping (address =&gt; address) public referralList;

  function InvestorWhiteList() {

  }

  function addInvestorToWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 &amp;&amp; !investorWhiteList[investor]);
    investorWhiteList[investor] = true;
  }

  function removeInvestorFromWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 &amp;&amp; investorWhiteList[investor]);
    investorWhiteList[investor] = false;
  }

  //when new user will contribute ICO contract will automatically send bonus to referral
  function addReferralOf(address investor, address referral) external onlyOwner {
    require(investor != 0x0 &amp;&amp; referral != 0x0 &amp;&amp; referralList[investor] == 0x0 &amp;&amp; investor != referral);
    referralList[investor] = referral;
  }

  function isAllowed(address investor) constant external returns (bool result) {
    return investorWhiteList[investor];
  }

  function getReferralOf(address investor) constant external returns (address result) {
    return referralList[investor];
  }
}

contract PriceReceiver {

  address public ethPriceProvider;

  modifier onlyEthPriceProvider() {
    require(msg.sender == ethPriceProvider);
    _;
  }

  function receiveEthPrice(uint ethUsdPrice) external;

  function setEthPriceProvider(address provider) external;
}

contract QuantorPreSale is Haltable, PriceReceiver {

  using SafeMath for uint;

  string public constant name = &quot;Quantor Token ICO&quot;;

  QuantorToken public token;

  address public beneficiary;

  InvestorWhiteList public investorWhiteList;

  uint public constant QNTUsdRate = 1; //0.01 cents fot one token

  uint public ethUsdRate;

  uint public btcUsdRate;

  uint public hardCap;

  uint public softCap;

  uint public collected = 0;

  uint public tokensSold = 0;

  uint public weiRefunded = 0;

  uint public startTime;

  uint public endTime;

  bool public softCapReached = false;

  bool public crowdsaleFinished = false;

  mapping (address =&gt; uint) public deposited;

  uint public constant PRICE_BEFORE_SOFTCAP = 65; // in cents * 100
  uint public constant PRICE_AFTER_SOFTCAP = 80; // in cents * 100

  event SoftCapReached(uint softCap);

  event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);

  event NewReferralTransfer(address indexed investor, address indexed referral, uint tokenAmount);

  event Refunded(address indexed holder, uint amount);

  modifier icoActive() {
    require(now &gt;= startTime &amp;&amp; now &lt; endTime);
    _;
  }

  modifier icoEnded() {
    require(now &gt;= endTime);
    _;
  }

  modifier minInvestment() {
    require(msg.value.mul(ethUsdRate).div(QNTUsdRate) &gt;= 50000 * 1 ether);
    _;
  }

  modifier inWhiteList() {
    require(investorWhiteList.isAllowed(msg.sender));
    _;
  }

  function QuantorPreSale(
    uint _hardCapQNT,
    uint _softCapQNT,
    address _token,
    address _beneficiary,
    address _investorWhiteList,
    uint _baseEthUsdPrice,

    uint _startTime,
    uint _endTime
  ) {
    hardCap = _hardCapQNT.mul(1 ether);
    softCap = _softCapQNT.mul(1 ether);

    token = QuantorToken(_token);
    beneficiary = _beneficiary;
    investorWhiteList = InvestorWhiteList(_investorWhiteList);

    startTime = _startTime;
    endTime = _endTime;

    ethUsdRate = _baseEthUsdPrice;
  }

  function() payable minInvestment inWhiteList {
    doPurchase();
  }

  function refund() external icoEnded {
    require(softCapReached == false);
    require(deposited[msg.sender] &gt; 0);

    uint refund = deposited[msg.sender];

    deposited[msg.sender] = 0;
    msg.sender.transfer(refund);

    weiRefunded = weiRefunded.add(refund);
    Refunded(msg.sender, refund);
  }

  function withdraw() external icoEnded onlyOwner {
    require(softCapReached);
    beneficiary.transfer(collected);
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

  function calculateTokens(uint ethReceived) internal view returns (uint) {
    if (!softCapReached) {
      uint tokens = ethReceived.mul(ethUsdRate.mul(100)).div(PRICE_BEFORE_SOFTCAP);
      if (softCap &gt;= tokensSold.add(tokens)) return tokens;
      uint firstPart = softCap.sub(tokensSold);
      uint  firstPartInWei = firstPart.mul(PRICE_BEFORE_SOFTCAP).div(ethUsdRate.mul(100));
      uint secondPartInWei = ethReceived.sub(firstPart.mul(PRICE_BEFORE_SOFTCAP).div(ethUsdRate.mul(100)));
      return firstPart.add(secondPartInWei.mul(ethUsdRate.mul(100)).div(PRICE_AFTER_SOFTCAP));
    }
    return ethReceived.mul(ethUsdRate.mul(100)).div(PRICE_AFTER_SOFTCAP);
  }

  function receiveEthPrice(uint ethUsdPrice) external onlyEthPriceProvider {
    require(ethUsdPrice &gt; 0);
    ethUsdRate = ethUsdPrice;
  }

  function setEthPriceProvider(address provider) external onlyOwner {
    require(provider != 0x0);
    ethPriceProvider = provider;
  }

  function setNewWhiteList(address newWhiteList) external onlyOwner {
    require(newWhiteList != 0x0);
    investorWhiteList = InvestorWhiteList(newWhiteList);
  }

  function doPurchase() private icoActive inNormalState {
    require(!crowdsaleFinished);

    uint tokens = calculateTokens(msg.value);

    uint newTokensSold = tokensSold.add(tokens);

    require(newTokensSold &lt;= hardCap);

    if (!softCapReached &amp;&amp; newTokensSold &gt;= softCap) {
      softCapReached = true;
      SoftCapReached(softCap);
    }

    collected = collected.add(msg.value);

    tokensSold = newTokensSold;

    deposited[msg.sender] = deposited[msg.sender].add(msg.value);

    token.transfer(msg.sender, tokens);
    NewContribution(msg.sender, tokens, msg.value);
  }

  function transferOwnership(address newOwner) onlyOwner icoEnded {
    super.transferOwnership(newOwner);
  }
}