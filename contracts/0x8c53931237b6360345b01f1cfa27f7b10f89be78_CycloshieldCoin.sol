//CycloShield Coin - www.cycloshieldcoin.com
//Created by Kenneth Tan of Fundyourselfnow.com

pragma solidity ^0.4.16;

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



contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  

  event Transfer(address indexed _from, address indexed _to, uint _value);

}

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  
  event Approval(address indexed _owner, address indexed _spender, uint _value);

}

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

    //code changed to comply with ERC20 standard
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    //balances[_from] = balances[_from].sub(_value); // this was removed
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

contract CycloshieldCoin is StandardToken, Ownable {
    string  public  constant name = &quot;Cycloshield Coin&quot;;
    string  public  constant symbol = &quot;CYS&quot;;
    uint    public  constant decimals = 18;
    uint    public  constant INITIAL_SUPPLY = 1000000000000000000000000000;
    address public  crowdsaleContract;
    bool    public  transferEnabled;
    

     modifier onlyWhenTransferEnabled() {
     if(msg.sender != crowdsaleContract) {
     require(transferEnabled);
     }
    _;
     
    }
    
    function CycloshieldCoin() {
    
        balances[msg.sender] = INITIAL_SUPPLY; 
        transferEnabled = true;
        totalSupply = INITIAL_SUPPLY;
        crowdsaleContract = msg.sender; //initial by setting crowdsalecontract location to owner
        Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
        }
    
    function setupCrowdsale(address _contract, bool _transferAllowed) onlyOwner {
        crowdsaleContract = _contract;
        transferEnabled = _transferAllowed;
    }
    function transfer(address _to, uint _value)
        onlyWhenTransferEnabled()
        returns (bool) {
        return super.transfer(_to, _value);
        }
    
    function transferFrom(address _from, address _to, uint _value) 
        onlyWhenTransferEnabled()
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
        }
   
    
    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) 
        onlyWhenTransferEnabled()
        returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) 
        onlyWhenTransferEnabled()
        returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain(ERC20 token, uint amount ) onlyOwner {
        token.transfer( owner, amount );
    }
    
    function ChangeTransferStatus() onlyOwner {
            if(transferEnabled == false){
            transferEnabled = true;
        } else{
            transferEnabled = false;
        }
    }
}