pragma solidity ^0.4.20;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) public pure  returns (uint256)  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b &gt; 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b)public pure returns (uint256) {
    uint256 c = a + b;
    assert(c&gt;=a &amp;&amp; c&gt;=b);
    return c;
  }

  function _assert(bool assertion)public pure {
    assert(!assertion);
  }
}


contract ERC20Interface {
  string public name;
  string public symbol;
  uint8 public  decimals;
  uint public totalSupply;
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
 
contract ERC20 is ERC20Interface,SafeMath {

   
    mapping(address =&gt; uint256) public balanceOf;

    
    mapping(address =&gt; mapping(address =&gt; uint256)) allowed;

    constructor(string _name) public {
       name = _name; 
       symbol = &quot;ETOO&quot;;
       decimals = 4;
       totalSupply = 1038688590000;
       balanceOf[msg.sender] = totalSupply;
    }

  
  function transfer(address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));
      require(balanceOf[msg.sender] &gt;= _value);
      require(balanceOf[ _to] + _value &gt;= balanceOf[ _to]);   // ??????

      balanceOf[msg.sender] =SafeMath.safeSub(balanceOf[msg.sender],_value) ;
      balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to] ,_value);

      
      emit Transfer(msg.sender, _to, _value);

      return true;
  }


  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require(_to != address(0));
      require(allowed[_from][msg.sender] &gt;= _value);
      require(balanceOf[_from] &gt;= _value);
      require(balanceOf[ _to] + _value &gt;= balanceOf[ _to]);

      balanceOf[_from] =SafeMath.safeSub(balanceOf[_from],_value) ;
      balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to],_value);

      allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender], _value);

      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      emit Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender) view returns (uint256 remaining) {
      return allowed[_owner][_spender];
  }

}


contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwer) public onlyOwner {
        owner = newOwer;
    }

}


contract AdvanceToken is ERC20, owned{

    mapping (address =&gt; bool) public frozenAccount;

    event AddSupply(uint amount);
    event FrozenFunds(address target, bool frozen);
    event Burn(address target, uint amount);

    constructor (string _name) ERC20(_name) public {

    }

    function mine(address target, uint amount) public onlyOwner {
        totalSupply =SafeMath.safeAdd(totalSupply,amount) ;
        balanceOf[target] = SafeMath.safeAdd(balanceOf[target],amount);

        emit AddSupply(amount);
        emit Transfer(0, target, amount);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


  function transfer(address _to, uint256 _value) public returns (bool success) {
        success = _transfer(msg.sender, _to, _value);
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] &gt;= _value);
        success =  _transfer(_from, _to, _value);
        allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender],_value) ;
  }

  function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
      require(_to != address(0));
      require(!frozenAccount[_from]);

      require(balanceOf[_from] &gt;= _value);
      require(balanceOf[ _to] + _value &gt;= balanceOf[ _to]);

      balanceOf[_from] =SafeMath.safeSub(balanceOf[_from],_value) ;
      balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to],_value) ;

      emit Transfer(_from, _to, _value);
      return true;
  }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] &gt;= _value);

        totalSupply =SafeMath.safeSub(totalSupply,_value) ;
        balanceOf[msg.sender] =SafeMath.safeSub(balanceOf[msg.sender],_value) ;

        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value)  public returns (bool success) {
        require(balanceOf[_from] &gt;= _value);
        require(allowed[_from][msg.sender] &gt;= _value);

        totalSupply =SafeMath.safeSub(totalSupply,_value) ;
        balanceOf[msg.sender] =SafeMath.safeSub(balanceOf[msg.sender], _value);
        allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender],_value);

        emit Burn(msg.sender, _value);
        return true;
    }
}