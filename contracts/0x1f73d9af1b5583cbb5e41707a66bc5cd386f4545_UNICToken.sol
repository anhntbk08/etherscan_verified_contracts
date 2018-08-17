pragma solidity ^0.4.18;

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
    uint256 c = a / b;
    return c;
  }

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

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address owner) public constant returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256 remaining);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping (address =&gt; uint256) public balances;
 
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (balances[msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to] &amp;&amp; _value &gt; 0 &amp;&amp; _to != address(this) &amp;&amp; _to != address(0)) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    } else { return false; }
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address =&gt; mapping (address =&gt; uint256)) allowed;
 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to] &amp;&amp; _value &gt; 0 &amp;&amp; _to != address(this) &amp;&amp; _to != address(0)) {
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    } else { return false; }
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
      if (((_value == 0) || (allowed[msg.sender][_spender] == 0)) &amp;&amp; _spender != address(this) &amp;&amp; _spender != address(0)) {
          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);
          return true;
      } else { return false; }
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}

contract UNICToken is owned, StandardToken {
    
    string public constant name = &#39;UNICToken&#39;;
    string public constant symbol = &#39;UNIC&#39;;
    uint8 public constant decimals = 18;
    
    uint256 public initialSupply = 250000000 * 10 ** uint256(decimals);
    
    address public icoManager;
    
    mapping (address =&gt; uint256) public WhiteList;

    modifier onlyManager() {
        require(msg.sender == icoManager);
        _;
    }

    function UNICToken() public onlyOwner {
      totalSupply = initialSupply;
      balances[msg.sender] = initialSupply;
    }

    function setICOManager(address _newIcoManager) public onlyOwner returns (bool) {
      assert(_newIcoManager != 0x0);
      icoManager = _newIcoManager;
    }
    
    function setWhiteList(address _contributor) public onlyManager {
      if(_contributor != 0x0){
        WhiteList[_contributor] = 1;
      }
    }
}

contract Crowdsale is owned, UNICToken {
    
  using SafeMath for uint;
  
  UNICToken public token = new UNICToken();
  
  address constant multisig = 0xDE4951a749DE77874ee72778512A2bA1e9032e7a;
  uint constant rate = 3400 * 1000000000000000000;
  
  uint public constant presaleStart = 1518084000;   /** 08.02 */
  uint public presaleEnd = 1520244000;              /** 05.03 */
  uint public presaleDiscount = 30;
  uint public presaleTokensLimit = 4250000 * 1000000000000000000;
  uint public presaleWhitelistDiscount = 40;
  uint public presaleWhitelistTokensLimit = 750000 * 1000000000000000000;

  uint public firstRoundICOStart = 1520848800;      /** 12.03 */
  uint public firstRoundICOEnd = 1522058400;        /** 26.03 */
  uint public firstRoundICODiscount = 15;
  uint public firstRoundICOTokensLimit = 6250000 * 1000000000000000000;

  uint public secondRoundICOStart = 1522922400;     /** 05.04 */
  uint public secondRoundICOEnd = 1524736800;       /** 26.04 */
  uint public secondRoundICOTokensLimit = 43750000 * 1000000000000000000;

  uint public etherRaised;
  uint public tokensSold;
  uint public tokensSoldWhitelist;

  modifier saleIsOn() {
    require((now &gt;= presaleStart &amp;&amp; now &lt;= presaleEnd) ||
      (now &gt;= firstRoundICOStart &amp;&amp; now &lt;= firstRoundICOEnd)
      || (now &gt;= secondRoundICOStart &amp;&amp; now &lt;= secondRoundICOEnd)
      );
    _;
  }

  function Crowdsale() public onlyOwner {
    etherRaised = 0;
    tokensSold = 0;
    tokensSoldWhitelist = 0;
  }
  
  function() external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _buyer) saleIsOn public payable {
    assert(_buyer != 0x0);
    if(msg.value &gt; 0){

      uint tokens = rate.mul(msg.value).div(1 ether);
      uint discountTokens = 0;
      if(now &gt;= presaleStart &amp;&amp; now &lt;= presaleEnd) {
          if(WhiteList[_buyer]==1) {
              discountTokens = tokens.mul(presaleWhitelistDiscount).div(100);
          }else{
              discountTokens = tokens.mul(presaleDiscount).div(100);
          }
      }
      if(now &gt;= firstRoundICOStart &amp;&amp; now &lt;= firstRoundICOEnd) {
          discountTokens = tokens.mul(firstRoundICODiscount).div(100);
      }

      uint tokensWithBonus = tokens.add(discountTokens);
      
      if(
          (now &gt;= presaleStart &amp;&amp; now &lt;= presaleEnd &amp;&amp; presaleTokensLimit &gt; tokensSold + tokensWithBonus &amp;&amp;
            ((WhiteList[_buyer]==1 &amp;&amp; presaleWhitelistTokensLimit &gt; tokensSoldWhitelist + tokensWithBonus) || WhiteList[_buyer]!=1)
          ) ||
          (now &gt;= firstRoundICOStart &amp;&amp; now &lt;= firstRoundICOEnd &amp;&amp; firstRoundICOTokensLimit &gt; tokensSold + tokensWithBonus) ||
          (now &gt;= secondRoundICOStart &amp;&amp; now &lt;= secondRoundICOEnd &amp;&amp; secondRoundICOTokensLimit &gt; tokensSold + tokensWithBonus)
      ){
      
        multisig.transfer(msg.value);
        etherRaised = etherRaised.add(msg.value);
        token.transfer(msg.sender, tokensWithBonus);
        tokensSold = tokensSold.add(tokensWithBonus);
        if(WhiteList[_buyer]==1) {
          tokensSoldWhitelist = tokensSoldWhitelist.add(tokensWithBonus);
        }
      }
    }
  }
}