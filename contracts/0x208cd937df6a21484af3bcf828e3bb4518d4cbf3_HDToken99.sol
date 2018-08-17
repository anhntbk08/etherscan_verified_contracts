pragma solidity ^0.4.18;

/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="493b2c242a26097b">[email&#160;protected]</a>π.com&gt;
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.37487895
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

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
  function Ownable() public{
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
  function transferOwnership(address newOwner) onlyOwner public{
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
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
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address =&gt; mapping (address =&gt; uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value &lt;= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {

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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Operational is Claimable {
    address public operator;

    function Operational(address _operator) public {
      operator = _operator;
    }

    modifier onlyOperator() {
      require(msg.sender == operator);
      _;
    }

    function transferOperator(address newOperator) public onlyOwner {
      require(newOperator != address(0));
      operator = newOperator;
    }

}

library DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct MyDateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (MyDateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i &lt;= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor &gt; timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i &lt;= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor &gt; timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = 0;//getHour(timestamp);

                // Minute
                dt.minute = 0;//getMinute(timestamp);

                // Second
                dt.second = 0;//getSecond(timestamp);

                // Day of week.
                dt.weekday = 0;//getWeekday(timestamp);

        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor &gt; timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i &lt; year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i &lt; month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public returns (bool) {
        require(_value &gt; 0);
        require(_value &lt;= balances[msg.sender]);
        // no need to require value &lt;= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        return true;
    }
}

contract LockableToken is Ownable, ReentrancyGuard, BurnableToken {

    using DateTime for uint;
    using SafeMath for uint256;

    mapping (uint256 =&gt; uint256) public lockedBalances; //新的锁定金额map，以yearx100+month为key，以此间解锁的所有金额总和为value
    uint256[] public lockedKeys;
    // For store all user&#39;s transfer records, eg: (0x000...000 =&gt; (201806 =&gt; 100) )
    mapping (address =&gt; mapping (uint256 =&gt; uint256) ) public payRecords;

    event TransferLocked(address indexed from,address indexed to,uint256 value, uint256 releaseTime);//new
    event ReleaseLockedBalance( uint256 value, uint256 releaseTime); //new
//    event ReleaseLockedBalance( uint256 releaseTime); //new
    /**
     * 新版锁定式转账
     * add by will 2018.1.17
     */
    function transferLockedToken(uint256 _value) public payable nonReentrant returns (bool) {

        require(_value &gt; 0 &amp;&amp; _value &lt;= balances[msg.sender]);

        uint256 unlockTime = now.add(26 weeks);
        uint theYear = unlockTime.parseTimestamp().year; //unlockTime.getYear();
        uint theMonth = unlockTime.parseTimestamp().month;//unlockTime.getMonth();
        uint256 theKey = (theYear.mul(100)).add(theMonth); //key = yearx100+month

        address _to = owner;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // Stored user&#39;s transfer per month
        var dt = now.parseTimestamp();
        var (curYear, curMonth) = (uint256(dt.year), uint256(dt.month) );
        uint256 yearMonth = (curYear.mul(100)).add(curMonth);
        payRecords[msg.sender][yearMonth] = payRecords[msg.sender][yearMonth].add(_value);

        if(lockedBalances[theKey] == 0) {
            lockedBalances[theKey] = _value; //key不存在则新增一条数据
            //lockedKeys.push(theKey); //记录新增的key
            push_or_update_key(theKey);
        }
        else {
            lockedBalances[theKey] = lockedBalances[theKey].add(_value); //key已存在则追加金额到此条数据
        }
        TransferLocked(msg.sender, _to, _value, unlockTime);
        return true;
    }

    function releaseLockedBalance() public returns (uint256 releaseAmount) {
        return releaseLockedBalance(now);
    }

    function releaseLockedBalance(uint256 unlockTime) internal returns (uint256 releaseAmount) {
        uint theYear = unlockTime.parseTimestamp().year;//unlockTime.getYear();
        uint theMonth = unlockTime.parseTimestamp().month;//unlockTime.getMonth();
        uint256 currentTime = (theYear.mul(100)).add(theMonth); //key = yearx100+month
        for (uint i = 0; i &lt; lockedKeys.length; i++) {
            uint256 theTime = lockedKeys[i]; //key就是解锁时间
            // by beard
            if(theTime == 0 || lockedBalances[theTime] == 0)
                continue;

            if(currentTime &gt;= theTime) {
                releaseAmount = releaseAmount.add(lockedBalances[theTime]); //解锁对应金额
                unlockBalanceByKey(theTime,i);
            }
        }
        ReleaseLockedBalance(releaseAmount,currentTime);
        return releaseAmount;
    }

    function unlockBalanceByKey(uint256 theKey,uint keyIndex) internal {
//        uint256 _time = theKey;
        uint256 _value = lockedBalances[theKey];
        balances[owner] = balances[owner].add(_value);
//        ReleaseLockedBalance(_value,_time);
        delete lockedBalances[theKey];
        delete lockedKeys[keyIndex];
    }

    function lockedBalance() public constant returns (uint256 value) {
        for (uint i=0; i &lt; lockedKeys.length; i++) {
            value = value.add(lockedBalances[lockedKeys[i]]);
        }
        return value;
    }

    // By beard
    function push_or_update_key(uint256 key) private {
        bool found_index = false;
        uint256 i=0;
        // Found a empty key.
        if(lockedKeys.length &gt;= 1) {
            for(; i&lt;lockedKeys.length; i++) {
                if(lockedKeys[i] == 0) {
                    found_index = true;
                    break;
                }
            }
        }

        // If found a empty key(value == 0) in lockedKeys array, reused it.
        if( found_index ) {
            lockedKeys[i] = key;
        } else {
            lockedKeys.push(key);
        }
    }
}

contract ReleaseableToken is Operational, LockableToken {
    using SafeMath for uint;
    using DateTime for uint256;
    bool secondYearUpdate = false; // Limit 更新到第二年
    uint256 public createTime; // 合约创建时间
    uint256 standardDecimals = 100000000; // 由于有8位小数，传进来的参数都是不带后面的小数，要有乘100000000的操作才能保证数量级一致

    uint256 public limitSupplyPerYear = standardDecimals.mul(600000000); // 每年释放的HDT的限额，第一年6亿
    uint256 public dailyLimit = standardDecimals.mul(10000000); // 每天释放的限额，1000万

    uint256 public supplyLimit = standardDecimals.mul(10000000000); // HDT总量100亿
    uint256 public releaseTokenTime = 0;

    event ReleaseSupply(address operator, uint256 value, uint256 releaseTime);
    event UnfreezeAmount(address receiver, uint256 amount, uint256 unfreezeTime);

    function ReleaseableToken(
                    uint256 initTotalSupply,
                    address operator
                ) public Operational(operator) {
        totalSupply = standardDecimals.mul(initTotalSupply); //所谓预发行30%，就是这么传进来的，传进来实际的70亿就好，分片内部完成
        createTime = now;
        balances[msg.sender] = totalSupply;
    }

    // 在 timestamp 时间点释放 releaseAmount 的 token
    function releaseSupply(uint256 releaseAmount) public onlyOperator returns(uint256 _actualRelease) {
        require(now &gt;= (releaseTokenTime.add(1 days)) );
        require(releaseAmount &lt;= dailyLimit);
        updateLimit();
        require(limitSupplyPerYear &gt; 0);
        if (releaseAmount &gt; limitSupplyPerYear) {
            if (totalSupply.add(limitSupplyPerYear) &gt; supplyLimit) {
                releaseAmount = supplyLimit.sub(totalSupply);
                totalSupply = supplyLimit;
            } else {
                totalSupply = totalSupply.add(limitSupplyPerYear);
                releaseAmount = limitSupplyPerYear;
            }
            limitSupplyPerYear = 0;
        } else {
            if (totalSupply.add(releaseAmount) &gt; supplyLimit) {
                releaseAmount = supplyLimit.sub(totalSupply);
                totalSupply = supplyLimit;
            } else {
                totalSupply = totalSupply.add(releaseAmount);
            }
            limitSupplyPerYear = limitSupplyPerYear.sub(releaseAmount);
        }

        releaseTokenTime = now;
        balances[owner] = balances[owner].add(releaseAmount);
        ReleaseSupply(msg.sender, releaseAmount, releaseTokenTime);
        return releaseAmount;
    }

    // 更新每年释放token的限制数量
    function updateLimit() internal {
        if (createTime.add(1 years) &lt; now &amp;&amp; !secondYearUpdate) {
            limitSupplyPerYear = standardDecimals.mul(1200000000); //120000000
            secondYearUpdate = true;
        }
        if (createTime.add(2 * 1 years) &lt; now) {
            if (totalSupply &lt; supplyLimit) {
                limitSupplyPerYear = supplyLimit.sub(totalSupply);
            }
        }
    }

    // 设置每天释放 token 的限额
    function setDailyLimit(uint256 _dailyLimit) public onlyOwner {
        dailyLimit = _dailyLimit;
    }
}

contract HDToken99 is ReleaseableToken {
    string public standard = &#39;2018012301&#39;;
    string public name = &#39;HDToken99&#39;;
    string public symbol = &#39;HDT99&#39;;
    uint8 public decimals = 8;

    function HDToken99(
                     uint256 initTotalSupply,
                     address operator
                     ) public ReleaseableToken(initTotalSupply, operator) {}
}