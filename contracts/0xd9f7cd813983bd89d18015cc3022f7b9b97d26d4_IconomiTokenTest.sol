pragma solidity ^0.4.0;

contract IconomiToken {

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event BlockLockSet(uint256 _value);
  event NewOwner(address _newOwner);

  modifier onlyOwner {
    if (msg.sender == owner) {
      _;
    }
  }

  modifier blockLock {
    if (!isLocked() || msg.sender == owner) {
      _;
    }
  }

  modifier checkIfToContract(address _to) {
    if(_to != address(this))  {
      _;
    }
  }

  uint256 public totalSupply;
  string public name;
  uint8 public decimals;
  string public symbol;
  string public version = &#39;0.0.1&#39;;
  address public owner;
  uint256 public lockedUntilBlock;

  function IconomiToken(
    uint256 _initialAmount,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    uint256 _lockedUntilBlock
    ) {
    balances[msg.sender] = _initialAmount;
    totalSupply = _initialAmount;
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
    lockedUntilBlock = _lockedUntilBlock;
    owner = msg.sender;
  }

  /* Approves and then calls the receiving contract */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

    //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
    //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
    if(!_spender.call(bytes4(sha3(&quot;receiveApproval(address,uint256,address,bytes)&quot;)), msg.sender, _value, this, _extraData)) { throw; }
    return true;

  }

  function transfer(address _to, uint256 _value) blockLock checkIfToContract(_to) returns (bool success) {

    if (balances[msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }

  }

  function transferFrom(address _from, address _to, uint256 _value) blockLock checkIfToContract(_to) returns (bool success) {

    if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }

  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function setBlockLock(uint256 _lockedUntilBlock) onlyOwner returns (bool success) {
    lockedUntilBlock = _lockedUntilBlock;
    BlockLockSet(_lockedUntilBlock);
    return true;
  }

  function isLocked() constant returns (bool success) {
    return lockedUntilBlock &gt; block.number;
  }

  function replaceOwner(address _newOwner) onlyOwner returns (bool success) {
    owner = _newOwner;
    NewOwner(_newOwner);
    return true;
  }

  mapping (address =&gt; uint256) balances;
  mapping (address =&gt; mapping (address =&gt; uint256)) allowed;
}


contract IconomiTokenTest is IconomiToken {
  function IconomiTokenTest(
    uint256 _initialAmount,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    uint256 _lockedUntilBlock
    ) IconomiToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol, _lockedUntilBlock) {
  }

  function destruct() onlyOwner {
    selfdestruct(owner);
  }
}