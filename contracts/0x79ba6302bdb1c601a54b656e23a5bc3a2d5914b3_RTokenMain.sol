pragma solidity 0.4.8;

contract owned {
  address public owner;
  function owned() {
    owner = msg.sender;
  }
  modifier onlyOwner {
    if(msg.sender != owner) throw;
    _;
  }
  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract RTokenBase {
  /* contract info */
  string public standard = &#39;Token 0.1&#39;;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  /* maintain a balance mapping of R tokens */
  mapping(address =&gt; uint256) public balanceMap;
  mapping(address =&gt; mapping(address =&gt; uint256)) public allowance;

  /* what to do on transfers */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /* Constructor */
  function RTokenBase(uint256 initialAmt, string tokenName, string tokenSymbol, uint8 decimalUnits) payable {
    balanceMap[msg.sender] = initialAmt;
    totalSupply = initialAmt;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

  /* send tokens */
  function transfer(address _to, uint256 _value) payable {
    if(
        (balanceMap[msg.sender] &lt; _value) ||
        (balanceMap[_to] + _value &lt; balanceMap[_to])
      )
      throw;
    balanceMap[msg.sender] -= _value;
    balanceMap[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }

  /* allow other contracts to spend tokens */
  function approve(address _spender, uint256 _value) returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    tokenRecipient spender = tokenRecipient(_spender);
    return true;
  }

  /* approve and notify */
  function approveAndCall(address _spender, uint256 _value, bytes _stuff) returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if(approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _stuff);
      return true;
    }
  }

  /* do a transfer */
  function transferFrom(address _from, address _to, uint256 _value) payable returns (bool success) {
    if(
        (balanceMap[_from] &lt; _value) ||
        (balanceMap[_to] + _value &lt; balanceMap[_to]) ||
        (_value &gt; allowance[_from][msg.sender])
      )
      throw;
    balanceMap[_from] -= _value;
    balanceMap[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  /* trap bad sends */
  function () {
    throw;
  }
}

contract RTokenMain is owned, RTokenBase {
  uint256 public sellPrice;
  uint256 public buyPrice;

  mapping(address =&gt; bool) public frozenAccount;

  event FrozenFunds(address target, bool frozen);

  function RTokenMain(uint256 initialAmt, string tokenName, string tokenSymbol, uint8 decimals, address centralMinter)
    RTokenBase(initialAmt, tokenName, tokenSymbol, decimals) {
      if(centralMinter != 0) {
        owner = centralMinter;
        balanceMap[msg.sender] = 0;
        balanceMap[owner] = initialAmt;
      }
    }

  function transfer(address _to, uint256 _value) payable {
    if(
        (balanceMap[msg.sender] &lt; _value) ||
        (balanceMap[_to] + _value &lt; balanceMap[_to]) ||
        (frozenAccount[msg.sender])
      )
      throw;
    balanceMap[msg.sender] -= _value;
    balanceMap[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) payable returns (bool success) {
    if(
        (frozenAccount[_from]) ||
        (balanceMap[_from] &lt; _value) ||
        (balanceMap[_to] + _value &lt; balanceMap[_to]) ||
        (_value &gt; allowance[_from][msg.sender])
      )
      throw;
    balanceMap[_from] -= _value;
    balanceMap[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  function mintToken(address target, uint256 mintedAmount) onlyOwner {
    balanceMap[target] += mintedAmount;
    totalSupply += mintedAmount;
    Transfer(0, this, mintedAmount);
    Transfer(this, target, mintedAmount);
  }

  function freezeAccount(address target, bool freeze) onlyOwner {
    frozenAccount[target] = freeze;
    FrozenFunds(target, freeze);
  }

  function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
    sellPrice = newSellPrice;
    buyPrice = newBuyPrice;
  }

  function buy() payable {
    uint amount = msg.value/buyPrice;
    if(balanceMap[this] &lt; amount)
      throw;
    balanceMap[msg.sender] += amount;
    balanceMap[this] -= amount;
    Transfer(this, msg.sender, amount);
  }

  function sell(uint256 amount) {
    if(balanceMap[msg.sender] &lt; amount)
      throw;
    balanceMap[msg.sender] -= amount;
    balanceMap[this] += amount;
    if(!msg.sender.send(amount*sellPrice))
      throw;
    else
      Transfer(msg.sender, this, amount);
  }
}