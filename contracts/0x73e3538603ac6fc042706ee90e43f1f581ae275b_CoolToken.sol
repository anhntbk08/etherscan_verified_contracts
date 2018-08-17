/**
 * Cool Crypto
 * Keep it Simple, Keep it Cool
 * @title CoolToken Smart Contract
 * @author CoolCrypto
 * @description A Cool Token For Everyone
 * 100 Million COOL
 * 4 Decimals
 * With love in 2017
 **/
pragma solidity &gt;=0.4.4;

//Cool safeMath
library safeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b &gt; 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b &lt;= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c &gt;= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a &gt;= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a &lt; b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a &gt;= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a &lt; b ? a : b;
  }
  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

//Cool Contract
contract CoolToken {
    string public standard = &#39;CoolToken&#39;;
    string public name = &#39;Cool&#39;;
    string public symbol = &#39;COOL&#39;;
    uint8 public decimals = 4;
    uint256 public totalSupply = 1000000000000;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address =&gt; uint256) public balanceOf;
    mapping(address =&gt; mapping(address =&gt; uint256)) public allowed;

    function Token() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) {
        require(_value &gt; 0 &amp;&amp; balanceOf[msg.sender] &gt;= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) {
        require(_value &gt; 0 &amp;&amp; balanceOf[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) {
        allowed[msg.sender][_spender] = _value;
    }

  
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function getBalanceOf(address _who) returns(uint256 amount) {
        return balanceOf[_who];
    }
}