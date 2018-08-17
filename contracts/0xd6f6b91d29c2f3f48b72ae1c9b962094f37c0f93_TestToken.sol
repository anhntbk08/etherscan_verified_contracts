pragma solidity ^0.4.2;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract TestToken {

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event BlockLockSet(uint256 _value);
  event NewOwner(address _newOwner);

  modifier onlyOwner {
    if (msg.sender == owner) {
      _;
    }
  }

  modifier blockLock(address _sender) {
    if (!isLocked() || _sender == owner) {
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

  function TestToken(
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

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  function transfer(address _to, uint256 _value) blockLock(msg.sender) checkIfToContract(_to) returns (bool success) {
    if (balances[msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) blockLock(_from) checkIfToContract(_to) returns (bool success) {
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