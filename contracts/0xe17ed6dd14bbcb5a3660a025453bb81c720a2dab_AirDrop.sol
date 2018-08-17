pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b &lt;= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20BasicInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}


/**
 * @title AirDropContract
 * Simply do the airdrop.
 */
contract AirDrop is Ownable {
    using SafeMath for uint256;

    // the amount that owner wants to send each time
    uint public airDropAmount;

    // the mapping to judge whether each address has already been airDropped
    mapping ( address =&gt; bool ) public invalidAirDrop;

    // flag to stop airdrop
    bool public stop = false;

    ERC20BasicInterface public erc20;

    uint256 public startTime;
    uint256 public endTime;

    // event
    event LogAirDrop(address indexed receiver, uint amount);
    event LogStop();
    event LogStart();
    event LogWithdrawal(address indexed receiver, uint amount);

    /**
    * @dev Constructor to set _airDropAmount and _tokenAddresss.
    * @param _airDropAmount The amount of token that is sent for doing airDrop.
    * @param _tokenAddress The address of token.
    */
    function AirDrop(uint256 _startTime, uint256 _endTime, uint _airDropAmount, address _tokenAddress) public {
        require(_startTime &gt;= now &amp;&amp;
            _endTime &gt;= _startTime &amp;&amp;
            _airDropAmount &gt; 0 &amp;&amp;
            _tokenAddress != address(0)
        );
        startTime = _startTime;
        endTime = _endTime;
        erc20 = ERC20BasicInterface(_tokenAddress);
        uint tokenDecimals = erc20.decimals();
        airDropAmount = _airDropAmount.mul(10 ** tokenDecimals);
    }

    /**
    * @dev Confirm that airDrop is available.
    * @return A bool to confirm that airDrop is available.
    */
    function isValidAirDropForAll() public view returns (bool) {
        bool validNotStop = !stop;
        bool validAmount = erc20.balanceOf(this) &gt;= airDropAmount;
        bool validPeriod = now &gt;= startTime &amp;&amp; now &lt;= endTime;
        return validNotStop &amp;&amp; validAmount &amp;&amp; validPeriod;
    }

    /**
    * @dev Confirm that airDrop is available for msg.sender.
    * @return A bool to confirm that airDrop is available for msg.sender.
    */
    function isValidAirDropForIndividual() public view returns (bool) {
        bool validNotStop = !stop;
        bool validAmount = erc20.balanceOf(this) &gt;= airDropAmount;
        bool validPeriod = now &gt;= startTime &amp;&amp; now &lt;= endTime;
        bool validAmountForIndividual = !invalidAirDrop[msg.sender];
        return validNotStop &amp;&amp; validAmount &amp;&amp; validPeriod &amp;&amp; validAmountForIndividual;
    }

    /**
    * @dev Do the airDrop to msg.sender
    */
    function receiveAirDrop() public {
        require(isValidAirDropForIndividual());

        // set invalidAirDrop of msg.sender to true
        invalidAirDrop[msg.sender] = true;

        // execute transferFrom
        require(erc20.transfer(msg.sender, airDropAmount));

        LogAirDrop(msg.sender, airDropAmount);
    }

    /**
    * @dev Change the state of stop flag
    */
    function toggle() public onlyOwner {
        stop = !stop;

        if (stop) {
            LogStop();
        } else {
            LogStart();
        }
    }

    /**
    * @dev Withdraw the amount of token that is remaining in this contract.
    * @param _address The address of EOA that can receive token from this contract.
    */
    function withdraw(address _address) public onlyOwner {
        require(stop || now &gt; endTime);
        require(_address != address(0));
        uint tokenBalanceOfContract = erc20.balanceOf(this);
        require(erc20.transfer(_address, tokenBalanceOfContract));
        LogWithdrawal(_address, tokenBalanceOfContract);
    }
}