pragma solidity ^0.4.23;

// File: contracts/NokuPricingPlan.sol

/**
* @dev The NokuPricingPlan contract defines the responsibilities of a Noku pricing plan.
*/
contract NokuPricingPlan {
    /**
    * @dev Pay the fee for the service identified by the specified name.
    * The fee amount shall already be approved by the client.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @param client The client of the target service.
    * @return true if fee has been paid.
    */
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

    /**
    * @dev Get the usage fee for the service identified by the specified name.
    * The returned fee amount shall be approved before using #payFee method.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @return The amount to approve before really paying such fee.
    */
    function usageFee(bytes32 serviceName, uint256 multiplier) public view returns(uint fee);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c &gt;= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/NokuTokenBurner.sol

contract BurnableERC20 is ERC20 {
    function burn(uint256 amount) public returns (bool burned);
}

/**
* @dev The NokuTokenBurner contract has the responsibility to burn the configured fraction of received
* ERC20-compliant tokens and distribute the remainder to the configured wallet.
*/
contract NokuTokenBurner is Pausable {
    using SafeMath for uint256;

    event LogNokuTokenBurnerCreated(address indexed caller, address indexed wallet);
    event LogBurningPercentageChanged(address indexed caller, uint256 indexed burningPercentage);

    // The wallet receiving the unburnt tokens.
    address public wallet;

    // The percentage of tokens to burn after being received (range [0, 100])
    uint256 public burningPercentage;

    // The cumulative amount of burnt tokens.
    uint256 public burnedTokens;

    // The cumulative amount of tokens transferred back to the wallet.
    uint256 public transferredTokens;

    /**
    * @dev Create a new NokuTokenBurner with predefined burning fraction.
    * @param _wallet The wallet receiving the unburnt tokens.
    */
    constructor(address _wallet) public {
        require(_wallet != address(0), &quot;_wallet is zero&quot;);
        
        wallet = _wallet;
        burningPercentage = 100;

        emit LogNokuTokenBurnerCreated(msg.sender, _wallet);
    }

    /**
    * @dev Change the percentage of tokens to burn after being received.
    * @param _burningPercentage The percentage of tokens to be burnt.
    */
    function setBurningPercentage(uint256 _burningPercentage) public onlyOwner {
        require(0 &lt;= _burningPercentage &amp;&amp; _burningPercentage &lt;= 100, &quot;_burningPercentage not in [0, 100]&quot;);
        require(_burningPercentage != burningPercentage, &quot;_burningPercentage equal to current one&quot;);
        
        burningPercentage = _burningPercentage;

        emit LogBurningPercentageChanged(msg.sender, _burningPercentage);
    }

    /**
    * @dev Called after burnable tokens has been transferred for burning.
    * @param _token THe extended ERC20 interface supported by the sent tokens.
    * @param _amount The amount of burnable tokens just arrived ready for burning.
    */
    function tokenReceived(address _token, uint256 _amount) public whenNotPaused {
        require(_token != address(0), &quot;_token is zero&quot;);
        require(_amount &gt; 0, &quot;_amount is zero&quot;);

        uint256 amountToBurn = _amount.mul(burningPercentage).div(100);
        if (amountToBurn &gt; 0) {
            assert(BurnableERC20(_token).burn(amountToBurn));
            
            burnedTokens = burnedTokens.add(amountToBurn);
        }

        uint256 amountToTransfer = _amount.sub(amountToBurn);
        if (amountToTransfer &gt; 0) {
            assert(BurnableERC20(_token).transfer(wallet, amountToTransfer));

            transferredTokens = transferredTokens.add(amountToTransfer);
        }
    }
}

// File: contracts/NokuFlatPlan.sol

/**
* @dev The NokuFlatPlan contract implements a flat pricing plan, manageable by the contract owner.
*/
contract NokuFlatPlan is NokuPricingPlan, Ownable {
    using SafeMath for uint256;

    event LogNokuFlatPlanCreated(
        address indexed caller,
        uint256 indexed paymentInterval,
        uint256 indexed flatFee,
        address nokuMasterToken,
        address tokenBurner
    );
    event LogPaymentIntervalChanged(address indexed caller, uint256 indexed paymentInterval);
    event LogFlatFeeChanged(address indexed caller, uint256 indexed flatFee);

    // The validity time interval of the flat subscription. 
    uint256 public paymentInterval;

    // When the next payment is required as timestamp in seconds from Unix epoch
    uint256 public nextPaymentTime;

    // The fee amount expressed in NOKU tokens.
    uint256 public flatFee;

    // The NOKU utility token used for paying fee  
    address public nokuMasterToken;

    // The contract responsible for burning the NOKU tokens paid as service fee
    address public tokenBurner;

    constructor(
        uint256 _paymentInterval,
        uint256 _flatFee,
        address _nokuMasterToken,
        address _tokenBurner
    )
    public
    {
        require(_paymentInterval != 0, &quot;_paymentInterval is zero&quot;);
        require(_flatFee != 0, &quot;_flatFee is zero&quot;);
        require(_nokuMasterToken != 0, &quot;_nokuMasterToken is zero&quot;);
        require(_tokenBurner != 0, &quot;_tokenBurner is zero&quot;);

        paymentInterval = _paymentInterval;
        flatFee = _flatFee;
        nokuMasterToken = _nokuMasterToken;
        tokenBurner = _tokenBurner;

        nextPaymentTime = block.timestamp;

        emit LogNokuFlatPlanCreated(
            msg.sender,
            _paymentInterval,
            _flatFee,
            _nokuMasterToken,
            _tokenBurner
        );
    }

    function setPaymentInterval(uint256 _paymentInterval) public onlyOwner {
        require(_paymentInterval != 0, &quot;_paymentInterval is zero&quot;);
        require(_paymentInterval != paymentInterval, &quot;_paymentInterval equal to current one&quot;);

        paymentInterval = _paymentInterval;

        emit LogPaymentIntervalChanged(msg.sender, _paymentInterval);
    }

    function setFlatFee(uint256 _flatFee) public onlyOwner {
        require(_flatFee != 0, &quot;_flatFee is zero&quot;);
        require(_flatFee != flatFee, &quot;_flatFee equal to current one&quot;);

        flatFee = _flatFee;

        emit LogFlatFeeChanged(msg.sender, _flatFee);
    }

    function isValidService(bytes32 _serviceName) public pure returns(bool isValid) {
        return _serviceName != 0;
    }

    /**
    * @dev Defines the operation by checking if flat fee has been paid or not.
    */
    function payFee(bytes32 _serviceName, uint256 _multiplier, address _client) public returns(bool paid) {
        require(isValidService(_serviceName), &quot;_serviceName in invalid&quot;);
        require(_multiplier != 0, &quot;_multiplier is zero&quot;);
        require(_client != 0, &quot;_client is zero&quot;);
        
        require(block.timestamp &lt; nextPaymentTime);

        return true;
    }

    function usageFee(bytes32 /*_serviceName*/, uint256 /*_multiplier*/) public view returns(uint fee) {
        return 0;
    }

    function paySubscription(address _client) public returns(bool paid) {
        require(_client != 0, &quot;_client is zero&quot;);

        nextPaymentTime = nextPaymentTime.add(paymentInterval);

        assert(ERC20(nokuMasterToken).transferFrom(_client, tokenBurner, flatFee));

        NokuTokenBurner(tokenBurner).tokenReceived(nokuMasterToken, flatFee);

        return true;
    }
}