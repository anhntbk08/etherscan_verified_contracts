pragma solidity 0.4.21;

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
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev revert()s if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/**
 * Math operations with safety checks
 */
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal returns (uint256) {
    require(b &gt; 0); // Solidity automatically revert()s when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub256(uint256 a, uint256 b) internal returns (uint256) {
    require(b &lt;= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
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
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev ERC20 interface with allowances. 
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address =&gt; uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length &gt;= size + 4);
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address =&gt; mapping (address =&gt; uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value &gt; _allowance) revert();

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public {

    //  To change the approve amount you first have to reduce the addresses
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) &amp;&amp; (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



/**
 * @title TeuToken
 * @dev The main TEU token contract
 * 
 */
 
contract TeuToken is StandardToken, Ownable{
  string public name = &quot;20-footEqvUnit&quot;;
  string public symbol = &quot;TEU&quot;;
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function TeuToken() public {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

  /**
   * @dev Allows the owner to burn the token
   * @param _value number of tokens to be burned.
   */
  function burn(uint _value) onlyOwner public {
    require(balances[msg.sender] &gt;= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}

/**
 * @title teuBatchTransfer
 * @dev Contract to transfer TEU to multiple wallet in batch
 * 
 */
contract teuBatchTransfer is Ownable {
	using SafeMath for uint256;

    TeuToken			                constant private		token = TeuToken(0xeEAc3F8da16bb0485a4A11c5128b0518DaC81448); // hard coded due to token already deployed
    
    /**
    * @dev transfer TEU token from one wallet to multiple wallets.  Sufficient TEU token allowance must be approved by _from to this contract before calling this method
    * @param _from address from which TEU will be transferred
    * @param _to addresses where TEU will be transferred to
    * @param _amount amount of TEU to be transferred
    */
    function transfer(address _from, address[] _to, uint256 _amount) public onlyOwner {
	    for (uint i = 0; i &lt; _to.length; i++) {
		    token.transferFrom(_from, _to[i], _amount);
	    }
    }  

}