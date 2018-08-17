pragma solidity ^0.4.19;

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}

contract DummyOVOToken {
  using SafeMath for uint256;

  address public owner;
  string public name = &quot;ICOVO&quot;;
  string public symbol = &quot;OVO&quot;;
  string public icon = &quot;QmXMDG2UnMQ7rFqxRN2LVA3ad2FLNTarDXZijdrctt8vpo&quot;;
  uint256 public decimals = 9;
  uint256 public totalSupply = 0;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed burner, uint256 amount);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  mapping (address =&gt; uint256) balances;
  mapping (address =&gt; mapping (address =&gt; uint256)) internal allowed;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function HWGCToken() public {
    owner = msg.sender;
  }

  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function burn(address _who, uint256 _value) onlyOwner public returns (bool) {
    require(_value &lt;= balances[_who]);

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_who, _value);
    Transfer(_who, address(0), _value);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value &lt;= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value &lt;= balances[_from]);
    require(_value &lt;= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}