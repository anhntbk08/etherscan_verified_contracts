/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
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
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

/// @title UintUtil
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2c484d424549406c4043435c5e45424b02435e4b">[email&#160;protected]</a>&gt;
/// @dev uint utility functions
library UintLib {
    using SafeMath  for uint;

    function tolerantSub(uint x, uint y) internal constant returns (uint z) {
        if (x &gt;= y)
            z = x - y;
        else
            z = 0;
    }

    function next(uint i, uint size) internal constant returns (uint) {
        return (i + 1) % size;
    }

    function prev(uint i, uint size) internal constant returns (uint) {
        return (i + size - 1) % size;
    }

    /// @dev calculate the square of Coefficient of Variation (CV)
    /// https://en.wikipedia.org/wiki/Coefficient_of_variation
    function cvsquare(
        uint[] arr,
        uint scale)
        internal
        constant
        returns (uint)
    {
        uint len = arr.length;
        require(len &gt; 1);
        require(scale &gt; 0);

        uint avg = 0;
        for (uint i = 0; i &lt; len; i++) {
            avg += arr[i];
        }

        avg = avg.div(len);

        if (avg == 0) {
            return 0;
        }

        uint cvs = 0;
        for (i = 0; i &lt; len; i++) {
            uint sub = 0;
            if (arr[i] &gt; avg) {
                sub = arr[i] - avg;
            } else {
                sub = avg - arr[i];
            }
            cvs += sub.mul(sub);
        }

        return cvs.mul(scale).div(avg).mul(scale).div(avg).div(len - 1);
    }
}

/// @title Token Register Contract
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e88387868f848189868fa8848787989a81868fc6879a8f">[email&#160;protected]</a>&gt;,
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d5b1b4bbbcb0b995b9babaa5a7bcbbb2fbbaa7b2">[email&#160;protected]</a>&gt;.
library Uint8Lib {
    function xorReduce(
        uint8[] arr,
        uint    len
        )
        internal
        constant
        returns (uint8 res)
    {
        res = arr[0];
        for (uint i = 1; i &lt; len; i++) {
            res ^= arr[i];
        }
    }
}

/// @title Token Register Contract
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a6c2c7c8cfc3cae6cac9c9d6d4cfc8c188c9d4c1">[email&#160;protected]</a>&gt;.
library ErrorLib {

    event Error(string message);

    /// @dev Check if condition hold, if not, log an exception and revert.
    function check(bool condition, string message) internal constant {
        if (!condition) {
            error(message);
        }
    }

    function error(string message) internal constant {
        Error(message);
        revert();
    }
}

/// @title Token Register Contract
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="caa1a5a4ada6a3aba4ad8aa6a5a5bab8a3a4ade4a5b8ad">[email&#160;protected]</a>&gt;,
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5034313e39353c103c3f3f2022393e377e3f2237">[email&#160;protected]</a>&gt;.
library Bytes32Lib {

    function xorReduce(
        bytes32[]   arr,
        uint        len
        )
        internal
        constant
        returns (bytes32 res)
    {
        res = arr[0];
        for (uint i = 1; i &lt; len; i++) {
            res = xorOp(res, arr[i]);
        }
    }

    function xorOp(
        bytes32 bs1,
        bytes32 bs2
        )
        internal
        constant
        returns (bytes32 res)
    {
        bytes memory temp = new bytes(32);
        for (uint i = 0; i &lt; 32; i++) {
            temp[i] = bs1[i] ^ bs2[i];
        }
        string memory str = string(temp);
        assembly {
            res := mload(add(str, 32))
        }
    }
}

/// @title Token Register Contract
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="84efebeae3e8ede5eae3c4e8ebebf4f6edeae3aaebf6e3">[email&#160;protected]</a>&gt;,
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f397929d9a969fb39f9c9c83819a9d94dd9c8194">[email&#160;protected]</a>&gt;.
contract TokenRegistry is Ownable {

    address[] public tokens;

    mapping (string =&gt; address) tokenSymbolMap;

    function registerToken(address _token, string _symbol)
        public
        onlyOwner
    {
        require(_token != address(0));
        require(!isTokenRegisteredBySymbol(_symbol));
        require(!isTokenRegistered(_token));
        tokens.push(_token);
        tokenSymbolMap[_symbol] = _token;
    }

    function unregisterToken(address _token, string _symbol)
        public
        onlyOwner
    {
        require(tokenSymbolMap[_symbol] == _token);
        delete tokenSymbolMap[_symbol];
        for (uint i = 0; i &lt; tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] == tokens[tokens.length - 1];
                tokens.length --;
                break;
            }
        }
    }

    function isTokenRegisteredBySymbol(string symbol)
        public
        constant
        returns (bool)
    {
        return tokenSymbolMap[symbol] != address(0);
    }

    function isTokenRegistered(address _token)
        public
        constant
        returns (bool)
    {

        for (uint i = 0; i &lt; tokens.length; i++) {
            if (tokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function getAddressBySymbol(string symbol)
        public
        constant
        returns (address)
    {
        return tokenSymbolMap[symbol];
    }

}

/// @title TokenTransferDelegate - Acts as a middle man to transfer ERC20 tokens
/// on behalf of different versioned of Loopring protocol to avoid ERC20
/// re-authorization.
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a0c4c1cec9c5cce0cccfcfd0d2c9cec78ecfd2c7">[email&#160;protected]</a>&gt;.
contract TokenTransferDelegate is Ownable {
    using Math for uint;

    ////////////////////////////////////////////////////////////////////////////
    /// Variables                                                            ///
    ////////////////////////////////////////////////////////////////////////////

    uint lastVersion = 0;
    address[] public versions;
    mapping (address =&gt; uint) public versioned;


    ////////////////////////////////////////////////////////////////////////////
    /// Modifiers                                                            ///
    ////////////////////////////////////////////////////////////////////////////

    modifier isVersioned(address addr) {
        if (versioned[addr] == 0) {
            revert();
        }
        _;
    }

    modifier notVersioned(address addr) {
        if (versioned[addr] &gt; 0) {
            revert();
        }
        _;
    }


    ////////////////////////////////////////////////////////////////////////////
    /// Events                                                               ///
    ////////////////////////////////////////////////////////////////////////////

    event VersionAdded(address indexed addr, uint version);

    event VersionRemoved(address indexed addr, uint version);


    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Add a Loopring protocol address.
    /// @param addr A loopring protocol address.
    function addVersion(address addr)
        onlyOwner
        notVersioned(addr)
    {
        versioned[addr] = ++lastVersion;
        versions.push(addr);
        VersionAdded(addr, lastVersion);
    }

    /// @dev Remove a Loopring protocol address.
    /// @param addr A loopring protocol address.
    function removeVersion(address addr)
        onlyOwner
        isVersioned(addr)
    {
        require(versioned[addr] &gt; 0);
        uint version = versioned[addr];
        delete versioned[addr];

        uint length = versions.length;
        for (uint i = 0; i &lt; length; i++) {
            if (versions[i] == addr) {
                versions[i] = versions[length - 1];
                versions.length -= 1;
                break;
            }
        }
        VersionRemoved(addr, version);
    }

    /// @return Amount of ERC20 token that can be spent by this contract.
    /// @param tokenAddress Address of token to transfer.
    /// @param _owner Address of the token owner.
    function getSpendable(
        address tokenAddress,
        address _owner
        )
        isVersioned(msg.sender)
        constant
        returns (uint)
    {

        var token = ERC20(tokenAddress);
        return token.allowance(
            _owner,
            address(this)
        ).min256(
            token.balanceOf(_owner)
        );
    }

    /// @dev Invoke ERC20 transferFrom method.
    /// @param token Address of token to transfer.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param value Amount of token to transfer.
    /// @return Tansfer result.
    function transferToken(
        address token,
        address from,
        address to,
        uint value)
        isVersioned(msg.sender)
        returns (bool)
    {
        if (from == to) {
            return false;
        } else {
            return ERC20(token).transferFrom(from, to, value);
        }
    }

    /// @dev Gets all versioned addresses.
    /// @return Array of versioned addresses.
    function getVersions()
        constant
        returns (address[])
    {
        return versions;
    }
}

/// @title Ring Hash Registry Contract
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e78c8889808b8e868980a78b888897958e8980c9889580">[email&#160;protected]</a>&gt;,
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3f5b5e51565a537f5350504f4d56515811504d58">[email&#160;protected]</a>&gt;.
contract RinghashRegistry {
    using Bytes32Lib    for bytes32[];
    using ErrorLib      for bool;
    using Uint8Lib      for uint8[];

    uint public blocksToLive;

    struct Submission {
        address ringminer;
        uint block;
    }

    mapping (bytes32 =&gt; Submission) submissions;


    /// Events

    event RinghashSubmitted(
        address indexed _ringminer,
        bytes32 indexed _ringhash
    );

    /// Constructor

    function RinghashRegistry(uint _blocksToLive)
        public
    {
        require(_blocksToLive &gt; 0);
        blocksToLive = _blocksToLive;
    }

    /// Public Functions

    function submitRinghash(
        uint        ringSize,
        address     ringminer,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList)
        public
    {
        bytes32 ringhash = calculateRinghash(
            ringSize,
            vList,
            rList,
            sList
        );

        ErrorLib.check(
            canSubmit(ringhash, ringminer),
            &quot;Ringhash submitted&quot;
        );

        submissions[ringhash] = Submission(ringminer, block.number);
        RinghashSubmitted(ringminer, ringhash);
    }

    function canSubmit(
        bytes32 ringhash,
        address ringminer)
        public
        constant
        returns (bool)
    {
        var submission = submissions[ringhash];
        return (
            submission.ringminer == address(0) || (
            submission.block + blocksToLive &lt; block.number) || (
            submission.ringminer == ringminer)
        );
    }

    /// @return True if a ring&#39;s hash has ever been submitted; false otherwise.
    function ringhashFound(bytes32 ringhash)
        public
        constant
        returns (bool)
    {

        return submissions[ringhash].ringminer != address(0);
    }

    /// @dev Calculate the hash of a ring.
    function calculateRinghash(
        uint        ringSize,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList)
        public
        constant
        returns (bytes32)
    {
        ErrorLib.check(
            ringSize == vList.length - 1 &amp;&amp; (
            ringSize == rList.length - 1) &amp;&amp; (
            ringSize == sList.length - 1),
            &quot;invalid ring data&quot;
        );

        return keccak256(
            vList.xorReduce(ringSize),
            rList.xorReduce(ringSize),
            sList.xorReduce(ringSize)
        );
    }
}

/// @title Loopring Token Exchange Protocol Contract Interface
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6f0b0e01060a032f0300001f1d06010841001d08">[email&#160;protected]</a>&gt;
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1e7571707972777f70795e7271716e6c77707930716c79">[email&#160;protected]</a>&gt;
contract LoopringProtocol {

    ////////////////////////////////////////////////////////////////////////////
    /// Constants                                                            ///
    ////////////////////////////////////////////////////////////////////////////
    uint    public constant FEE_SELECT_LRC               = 0;
    uint    public constant FEE_SELECT_MARGIN_SPLIT      = 1;
    uint    public constant FEE_SELECT_MAX_VALUE         = 1;

    uint    public constant MARGIN_SPLIT_PERCENTAGE_BASE = 100;


    ////////////////////////////////////////////////////////////////////////////
    /// Structs                                                              ///
    ////////////////////////////////////////////////////////////////////////////

    /// @param tokenS       Token to sell.
    /// @param tokenB       Token to buy.
    /// @param amountS      Maximum amount of tokenS to sell.
    /// @param amountB      Minimum amount of tokenB to buy if all amountS sold.
    /// @param timestamp    Indicating whtn this order is created/signed.
    /// @param ttl          Indicating after how many seconds from `timestamp`
    ///                     this order will expire.
    /// @param salt         A random number to make this order&#39;s hash unique.
    /// @param lrcFee       Max amount of LRC to pay for miner. The real amount
    ///                     to pay is proportional to fill amount.
    /// @param buyNoMoreThanAmountB -
    ///                     If true, this order does not accept buying more
    ///                     than `amountB`.
    /// @param marginSplitPercentage -
    ///                     The percentage of margin paid to miner.
    /// @param v            ECDSA signature parameter v.
    /// @param r            ECDSA signature parameters r.
    /// @param s            ECDSA signature parameters s.
    struct Order {
        address owner;
        address tokenS;
        address tokenB;
        uint    amountS;
        uint    amountB;
        uint    timestamp;
        uint    ttl;
        uint    salt;
        uint    lrcFee;
        bool    buyNoMoreThanAmountB;
        uint8   marginSplitPercentage;
        uint8   v;
        bytes32 r;
        bytes32 s;
    }


    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Submit a order-ring for validation and settlement.
    /// @param addressList  List of each order&#39;s owner and tokenS. Note that next
    ///                     order&#39;s `tokenS` equals this order&#39;s `tokenB`.
    /// @param uintArgsList List of uint-type arguments in this order:
    ///                     amountS, AmountB, rateAmountS, timestamp, ttl, salt,
    ///                     and lrcFee.
    /// @param uint8ArgsList -
    ///                     List of unit8-type arguments, in this order:
    ///                     marginSplitPercentageList, feeSelectionList.
    /// @param vList        List of v for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     v value of the ring signature.
    /// @param rList        List of r for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     r value of the ring signature.
    /// @param sList        List of s for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     s value of the ring signature.
    /// @param ringminer    The address that signed this tx.
    /// @param feeRecepient The recepient address for fee collection. If this is
    ///                     &#39;0x0&#39;, all fees will be paid to the address who had
    ///                     signed this transaction, not `msg.sender`. Noted if
    ///                     LRC need to be paid back to order owner as the result
    ///                     of fee selection model, LRC will also be sent from
    ///                     this address.
    /// @param throwIfLRCIsInsuffcient -
    ///                     If true, throw exception if any order&#39;s spendable
    ///                     LRC amount is smaller than requried; if false, ring-
    ///                     minor will give up collection the LRC fee.
    function submitRing(
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         ringminer,
        address         feeRecepient,
        bool            throwIfLRCIsInsuffcient
        ) public;

    /// @dev Cancel a order. cancel amount(amountS or amountB) can be specified
    ///      in orderValues.
    /// @param addresses          owner, tokenS, tokenB
    /// @param orderValues        amountS, amountB, timestamp, ttl, salt, lrcFee,
    ///                           cancelAmountS, and cancelAmountB.
    /// @param marginSplitPercentage -
    /// @param buyNoMoreThanAmountB -
    /// @param v                  Order ECDSA signature parameter v.
    /// @param r                  Order ECDSA signature parameters r.
    /// @param s                  Order ECDSA signature parameters s.
    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        ) public;

    /// @dev   Set a cutoff timestamp to invalidate all orders whose timestamp
    ///        is smaller than or equal to the new value of the address&#39;s cutoff
    ///        timestamp.
    /// @param cutoff The cutoff timestamp, will default to `block.timestamp`
    ///        if it is 0.
    function setCutoff(uint cutoff) public;
}

/// @title Loopring Token Exchange Protocol Implementation Contract v1
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b6d2d7d8dfd3daf6dad9d9c6c4dfd8d198d9c4d1">[email&#160;protected]</a>&gt;,
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a5cecacbc2c9ccc4cbc2e5c9cacad5d7cccbc28bcad7c2">[email&#160;protected]</a>&gt;
contract LoopringProtocolImpl is LoopringProtocol {
    using Math      for uint;
    using SafeMath  for uint;
    using UintLib   for uint;

    ////////////////////////////////////////////////////////////////////////////
    /// Variables                                                            ///
    ////////////////////////////////////////////////////////////////////////////

    address public  lrcTokenAddress             = address(0);
    address public  tokenRegistryAddress        = address(0);
    address public  ringhashRegistryAddress     = address(0);
    address public  delegateAddress             = address(0);

    uint    public  maxRingSize                 = 0;
    uint    public  ringIndex                   = 0;
    bool    private entered                     = false;

    // Exchange rate (rate) is the amount to sell or sold divided by the amount
    // to buy or bought.
    //
    // Rate ratio is the ratio between executed rate and an order&#39;s original
    // rate.
    //
    // To require all orders&#39; rate ratios to have coefficient ofvariation (CV)
    // smaller than 2.5%, for an example , rateRatioCVSThreshold should be:
    //     `(0.025 * RATE_RATIO_SCALE)^2` or 62500.
    uint    public  rateRatioCVSThreshold       = 0;

    uint    public constant RATE_RATIO_SCALE    = 10000;

    // The following two maps are used to keep trace of order fill and
    // cancellation history.
    mapping (bytes32 =&gt; uint) public filled;
    mapping (bytes32 =&gt; uint) public cancelled;

    // A map from address to its cutoff timestamp.
    mapping (address =&gt; uint) public cutoffs;


    ////////////////////////////////////////////////////////////////////////////
    /// Structs                                                              ///
    ////////////////////////////////////////////////////////////////////////////

    struct Rate {
        uint amountS;
        uint amountB;
    }

    /// @param order        The original order
    /// @param orderHash    The order&#39;s hash
    /// @param feeSelection -
    ///                     A miner-supplied value indicating if LRC (value = 0)
    ///                     or margin split is choosen by the miner (value = 1).
    ///                     We may support more fee model in the future.
    /// @param rate         Exchange rate provided by miner.
    /// @param availableAmountS -
    ///                     The actual spendable amountS.
    /// @param fillAmountS  Amount of tokenS to sell, calculated by protocol.
    /// @param lrcReward    The amount of LRC paid by miner to order owner in
    ///                     exchange for margin split.
    /// @param lrcFee       The amount of LR paid by order owner to miner.
    /// @param splitS      TokenS paid to miner.
    /// @param splitB      TokenB paid to miner.
    struct OrderState {
        Order   order;
        bytes32 orderHash;
        uint8   feeSelection;
        Rate    rate;
        uint    availableAmountS;
        uint    fillAmountS;
        uint    lrcReward;
        uint    lrcFee;
        uint    splitS;
        uint    splitB;
    }

    struct Ring {
        bytes32      ringhash;
        OrderState[] orders;
        address      miner;
        address      feeRecepient;
        bool         throwIfLRCIsInsuffcient;
    }


    ////////////////////////////////////////////////////////////////////////////
    /// Events                                                               ///
    ////////////////////////////////////////////////////////////////////////////

    event RingMined(
        uint                _ringIndex,
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _ringhash,
        address     indexed _miner,
        address     indexed _feeRecepient,
        bool                _ringhashFound);

    event OrderFilled(
        uint                _ringIndex,
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _ringhash,
        bytes32             _prevOrderHash,
        bytes32     indexed _orderHash,
        bytes32              _nextOrderHash,
        uint                _amountS,
        uint                _amountB,
        uint                _lrcReward,
        uint                _lrcFee);

    event OrderCancelled(
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _orderHash,
        uint                _amountCancelled);

    event CutoffTimestampChanged(
        uint                _time,
        uint                _blocknumber,
        address     indexed _address,
        uint                _cutoff);


    ////////////////////////////////////////////////////////////////////////////
    /// Constructor                                                          ///
    ////////////////////////////////////////////////////////////////////////////

    function LoopringProtocolImpl(
        address _lrcTokenAddress,
        address _tokenRegistryAddress,
        address _ringhashRegistryAddress,
        address _delegateAddress,
        uint    _maxRingSize,
        uint    _rateRatioCVSThreshold
        )
        public
    {
        require(address(0) != _lrcTokenAddress);
        require(address(0) != _tokenRegistryAddress);
        require(address(0) != _delegateAddress);

        require(_maxRingSize &gt; 1);
        require(_rateRatioCVSThreshold &gt; 0);

        lrcTokenAddress = _lrcTokenAddress;
        tokenRegistryAddress = _tokenRegistryAddress;
        ringhashRegistryAddress = _ringhashRegistryAddress;
        delegateAddress = _delegateAddress;
        maxRingSize = _maxRingSize;
        rateRatioCVSThreshold = _rateRatioCVSThreshold;
    }

    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Disable default function.
    function ()
        payable
    {
        revert();
    }

    /// @dev Submit a order-ring for validation and settlement.
    /// @param addressList  List of each order&#39;s tokenS. Note that next order&#39;s
    ///                     `tokenS` equals this order&#39;s `tokenB`.
    /// @param uintArgsList List of uint-type arguments in this order:
    ///                     amountS, amountB, timestamp, ttl, salt, lrcFee,
    ///                     rateAmountS.
    /// @param uint8ArgsList -
    ///                     List of unit8-type arguments, in this order:
    ///                     marginSplitPercentageList,feeSelectionList.
    /// @param vList        List of v for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     v value of the ring signature.
    /// @param rList        List of r for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     r value of the ring signature.
    /// @param sList        List of s for each order. This list is 1-larger than
    ///                     the previous lists, with the last element being the
    ///                     s value of the ring signature.
    /// @param ringminer    The address that signed this tx.
    /// @param feeRecepient The recepient address for fee collection. If this is
    ///                     &#39;0x0&#39;, all fees will be paid to the address who had
    ///                     signed this transaction, not `msg.sender`. Noted if
    ///                     LRC need to be paid back to order owner as the result
    ///                     of fee selection model, LRC will also be sent from
    ///                     this address.
    /// @param throwIfLRCIsInsuffcient -
    ///                     If true, throw exception if any order&#39;s spendable
    ///                     LRC amount is smaller than requried; if false, ring-
    ///                     minor will give up collection the LRC fee.
    function submitRing(
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         ringminer,
        address         feeRecepient,
        bool            throwIfLRCIsInsuffcient
        )
        public
    {
        ErrorLib.check(!entered, &quot;attempted to re-ent submitRing function&quot;);
        entered = true;

        //Check ring size
        uint ringSize = addressList.length;
        ErrorLib.check(
            ringSize &gt; 1 &amp;&amp; ringSize &lt;= maxRingSize,
            &quot;invalid ring size&quot;
        );

        verifyInputDataIntegrity(
            ringSize,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList
        );

        verifyTokensRegistered(addressList);

        var ringhashRegistry = RinghashRegistry(ringhashRegistryAddress);

        bytes32 ringhash = ringhashRegistry.calculateRinghash(
            ringSize,
            vList,
            rList,
            sList
        );

        ErrorLib.check(
            ringhashRegistry.canSubmit(ringhash, feeRecepient),
            &quot;Ring claimed by others&quot;
        );

        verifySignature(
            ringminer,
            ringhash,
            vList[ringSize],
            rList[ringSize],
            sList[ringSize]
        );

        //Assemble input data into a struct so we can pass it to functions.
        var orders = assembleOrders(
            ringSize,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList
        );

        if (feeRecepient == address(0)) {
            feeRecepient = ringminer;
        }

        handleRing(
            ringhash,
            orders,
            ringminer,
            feeRecepient,
            throwIfLRCIsInsuffcient
        );

        entered = false;
    }

    /// @dev Cancel a order. Amount (amountS or amountB) to cancel can be
    ///                           specified using orderValues.
    /// @param addresses          owner, tokenS, tokenB
    /// @param orderValues        amountS, amountB, timestamp, ttl, salt,
    ///                           lrcFee, and cancelAmount
    /// @param buyNoMoreThanAmountB -
    ///                           If true, this order does not accept buying
    ///                           more than `amountB`.
    /// @param marginSplitPercentage -
    ///                           The percentage of margin paid to miner.
    /// @param v                  Order ECDSA signature parameter v.
    /// @param r                  Order ECDSA signature parameters r.
    /// @param s                  Order ECDSA signature parameters s.

    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        public
    {
        uint cancelAmount = orderValues[6];
        ErrorLib.check(cancelAmount &gt; 0, &quot;amount to cancel is zero&quot;);

        var order = Order(
            addresses[0],
            addresses[1],
            addresses[2],
            orderValues[0],
            orderValues[1],
            orderValues[2],
            orderValues[3],
            orderValues[4],
            orderValues[5],
            buyNoMoreThanAmountB,
            marginSplitPercentage,
            v,
            r,
            s
        );

        ErrorLib.check(msg.sender == order.owner, &quot;cancelOrder not submitted by order owner&quot;);

        bytes32 orderHash = calculateOrderHash(order);

        verifySignature(
            order.owner,
            orderHash,
            order.v,
            order.r,
            order.s
        );

        cancelled[orderHash] = cancelled[orderHash].add(cancelAmount);

        OrderCancelled(
            block.timestamp,
            block.number,
            orderHash,
            cancelAmount
        );
    }

    /// @dev   Set a cutoff timestamp to invalidate all orders whose timestamp
    ///        is smaller than or equal to the new value of the address&#39;s cutoff
    ///        timestamp.
    /// @param cutoff The cutoff timestamp, will default to `block.timestamp`
    ///        if it is 0.
    function setCutoff(uint cutoff)
        public
    {
        uint t = cutoff;
        if (t == 0) {
            t = block.timestamp;
        }

        ErrorLib.check(
            cutoffs[msg.sender] &lt; t,
            &quot;attempted to set cutoff to a smaller value&quot;
        );

        cutoffs[msg.sender] = t;

        CutoffTimestampChanged(
            block.timestamp,
            block.number,
            msg.sender,
            t
        );
    }

    ////////////////////////////////////////////////////////////////////////////
    /// Internal &amp; Private Functions                                         ///
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Validate a ring.
    function verifyRingHasNoSubRing(Ring ring)
        internal
        constant
    {
        uint ringSize = ring.orders.length;
        // Check the ring has no sub-ring.
        for (uint i = 0; i &lt; ringSize - 1; i++) {
            address tokenS = ring.orders[i].order.tokenS;
            for (uint j = i + 1; j &lt; ringSize; j++) {
                ErrorLib.check(
                    tokenS != ring.orders[j].order.tokenS,
                    &quot;found sub-ring&quot;
                );
            }
        }
    }

    function verifyTokensRegistered(address[2][] addressList)
        internal
        constant
    {
        var registryContract = TokenRegistry(tokenRegistryAddress);
        for (uint i = 0; i &lt; addressList.length; i++) {
            ErrorLib.check(
                registryContract.isTokenRegistered(addressList[i][1]),
                &quot;token not registered&quot;
            );
        }
    }

    function handleRing(
        bytes32 ringhash,
        OrderState[] orders,
        address miner,
        address feeRecepient,
        bool throwIfLRCIsInsuffcient
        )
        internal
    {
        var ring = Ring(
            ringhash,
            orders,
            miner,
            feeRecepient,
            throwIfLRCIsInsuffcient
        );

        // Do the hard work.
        verifyRingHasNoSubRing(ring);

        // Exchange rates calculation are performed by ring-miners as solidity
        // cannot get power-of-1/n operation, therefore we have to verify
        // these rates are correct.
        verifyMinerSuppliedFillRates(ring);

        // Scale down each order independently by substracting amount-filled and
        // amount-cancelled. Order owner&#39;s current balance and allowance are
        // not taken into consideration in these operations.
        scaleRingBasedOnHistoricalRecords(ring);

        // Based on the already verified exchange rate provided by ring-miners,
        // we can furthur scale down orders based on token balance and allowance,
        // then find the smallest order of the ring, then calculate each order&#39;s
        // `fillAmountS`.
        calculateRingFillAmount(ring);

        // Calculate each order&#39;s `lrcFee` and `lrcRewrard` and splict how much
        // of `fillAmountS` shall be paid to matching order or miner as margin
        // split.
        calculateRingFees(ring);

        /// Make payments.
        settleRing(ring);

        RingMined(
            ringIndex++,
            block.timestamp,
            block.number,
            ring.ringhash,
            ring.miner,
            ring.feeRecepient,
            RinghashRegistry(ringhashRegistryAddress).ringhashFound(ring.ringhash)
        );
    }

    function settleRing(Ring ring)
        internal
    {
        uint ringSize = ring.orders.length;
        var delegate = TokenTransferDelegate(delegateAddress);

        for (uint i = 0; i &lt; ringSize; i++) {
            var state = ring.orders[i];
            var prev = ring.orders[i.prev(ringSize)];
            var next = ring.orders[i.next(ringSize)];

            // Pay tokenS to previous order, or to miner as previous order&#39;s
            // margin split or/and this order&#39;s margin split.

            delegate.transferToken(
                state.order.tokenS,
                state.order.owner,
                prev.order.owner,
                state.fillAmountS - prev.splitB
            );

            if (prev.splitB + state.splitS &gt; 0) {
                delegate.transferToken(
                    state.order.tokenS,
                    state.order.owner,
                    ring.feeRecepient,
                    prev.splitB + state.splitS
                );
            }

            // Pay LRC
            if (state.lrcReward &gt; 0) {
                delegate.transferToken(
                    lrcTokenAddress,
                    ring.feeRecepient,
                    state.order.owner,
                    state.lrcReward
                );
            }

            if (state.lrcFee &gt; 0) {
                delegate.transferToken(
                    lrcTokenAddress,
                    state.order.owner,
                    ring.feeRecepient,
                    state.lrcFee
                );
            }

            // Update fill records
            if (state.order.buyNoMoreThanAmountB) {
                filled[state.orderHash] += next.fillAmountS;
            } else {
                filled[state.orderHash] += state.fillAmountS;
            }

            OrderFilled(
                ringIndex,
                block.timestamp,
                block.number,
                ring.ringhash,
                prev.orderHash,
                state.orderHash,
                next.orderHash,
                state.fillAmountS + state.splitS,
                next.fillAmountS - state.splitB,
                state.lrcReward,
                state.lrcFee
            );
        }

    }

    function verifyMinerSuppliedFillRates(Ring ring)
        internal
        constant
    {
        var orders = ring.orders;
        uint ringSize = orders.length;
        uint[] memory rateRatios = new uint[](ringSize);

        for (uint i = 0; i &lt; ringSize; i++) {
            uint s1b0 = orders[i].rate.amountS.mul(orders[i].order.amountB);
            uint s0b1 = orders[i].order.amountS.mul(orders[i].rate.amountB);

            ErrorLib.check(
                s1b0 &lt;= s0b1,
                &quot;miner supplied exchange rate provides invalid discount&quot;
            );

            rateRatios[i] = RATE_RATIO_SCALE.mul(s1b0).div(s0b1);
        }

        uint cvs = UintLib.cvsquare(rateRatios, RATE_RATIO_SCALE);

        ErrorLib.check(
            cvs &lt;= rateRatioCVSThreshold,
            &quot;miner supplied exchange rate is not evenly discounted&quot;
        );
    }

    function calculateRingFees(Ring ring)
        internal
        constant
    {
        uint minerLrcSpendable = getLRCSpendable(ring.feeRecepient);
        uint ringSize = ring.orders.length;

        for (uint i = 0; i &lt; ringSize; i++) {
            var state = ring.orders[i];
            var next = ring.orders[i.next(ringSize)];

            if (state.feeSelection == FEE_SELECT_LRC) {

                uint lrcSpendable = getLRCSpendable(state.order.owner);

                if (lrcSpendable &lt; state.lrcFee) {
                    ErrorLib.check(
                        !ring.throwIfLRCIsInsuffcient,
                        &quot;order LRC balance insuffcient&quot;
                    );

                    state.lrcFee = lrcSpendable;
                    minerLrcSpendable += lrcSpendable;
                }

            } else if (state.feeSelection == FEE_SELECT_MARGIN_SPLIT) {
                if (minerLrcSpendable &gt;= state.lrcFee) {
                    if (state.order.buyNoMoreThanAmountB) {
                        uint splitS = next.fillAmountS.mul(
                            state.order.amountS
                        ).div(
                            state.order.amountB
                        ).sub(
                            state.fillAmountS
                        );

                        state.splitS = splitS.mul(
                            state.order.marginSplitPercentage
                        ).div(
                            MARGIN_SPLIT_PERCENTAGE_BASE
                        );
                    } else {
                        uint splitB = next.fillAmountS.sub(state.fillAmountS
                            .mul(state.order.amountB)
                            .div(state.order.amountS)
                        );

                        state.splitB = splitB.mul(
                            state.order.marginSplitPercentage
                        ).div(
                            MARGIN_SPLIT_PERCENTAGE_BASE
                        );
                    }

                    // This implicits order with smaller index in the ring will
                    // be paid LRC reward first, so the orders in the ring does
                    // mater.
                    if (state.splitS &gt; 0 || state.splitB &gt; 0) {
                        minerLrcSpendable = minerLrcSpendable.sub(state.lrcFee);
                        state.lrcReward = state.lrcFee;
                    }
                    state.lrcFee = 0;
                }
            } else {
                ErrorLib.error(&quot;unsupported fee selection value&quot;);
            }
        }

    }

    function calculateRingFillAmount(Ring ring)
        internal
        constant
    {
        uint ringSize = ring.orders.length;
        uint smallestIdx = 0;
        uint i;
        uint j;

        for (i = 0; i &lt; ringSize; i++) {
            j = i.next(ringSize);

            uint res = calculateOrderFillAmount(
                ring.orders[i],
                ring.orders[j]
            );

            if (res == 1) {
                smallestIdx = i;
            } else if (res == 2) {
                smallestIdx = j;
            }
        }

        for (i = 0; i &lt; smallestIdx; i++) {
            j = i.next(ringSize);
            calculateOrderFillAmount(
                ring.orders[i],
                ring.orders[j]
            );
        }
    }

    /// @return 0 if neither order is the smallest one;
    ///         1 if &#39;state&#39; is the smallest order;
    ///         2 if &#39;next&#39; is the smallest order.
    function calculateOrderFillAmount(
        OrderState state,
        OrderState next
        )
        internal
        constant
        returns (uint whichIsSmaller)
    {
        uint fillAmountB = state.fillAmountS.mul(
            state.rate.amountB
        ).div(
            state.rate.amountS
        );

        if (state.order.buyNoMoreThanAmountB) {
            if (fillAmountB &gt; state.order.amountB) {
                fillAmountB = state.order.amountB;

                state.fillAmountS = fillAmountB.mul(
                    state.rate.amountS
                ).div(
                    state.rate.amountB
                );

                whichIsSmaller = 1;
            }
        }

        state.lrcFee = state.order.lrcFee.mul(
            state.fillAmountS
        ).div(
            state.order.amountS
        );

        if (fillAmountB &lt;= next.fillAmountS) {
            next.fillAmountS = fillAmountB;
        } else {
            whichIsSmaller = 2;
        }
    }

    /// @dev Scale down all orders based on historical fill or cancellation
    ///      stats but key the order&#39;s original exchange rate.
    function scaleRingBasedOnHistoricalRecords(Ring ring)
        internal
        constant
    {
        uint ringSize = ring.orders.length;

        for (uint i = 0; i &lt; ringSize; i++) {
            var state = ring.orders[i];
            var order = state.order;

            if (order.buyNoMoreThanAmountB) {
                uint amountB = order.amountB.sub(
                    filled[state.orderHash]
                ).tolerantSub(
                    cancelled[state.orderHash]
                );

                order.amountS = amountB.mul(order.amountS).div(order.amountB);
                order.lrcFee = amountB.mul(order.lrcFee).div(order.amountB);

                order.amountB = amountB;
            } else {
                uint amountS = order.amountS.sub(
                    filled[state.orderHash]
                ).tolerantSub(
                    cancelled[state.orderHash]
                );

                order.amountB = amountS.mul(order.amountB).div(order.amountS);
                order.lrcFee = amountS.mul(order.lrcFee).div(order.amountS);

                order.amountS = amountS;
            }

            ErrorLib.check(order.amountS &gt; 0, &quot;amountS is zero&quot;);
            ErrorLib.check(order.amountB &gt; 0, &quot;amountB is zero&quot;);

            state.fillAmountS = order.amountS.min256(state.availableAmountS);
        }
    }

    /// @return Amount of ERC20 token that can be spent by this contract.
    function getSpendable(
        address tokenAddress,
        address tokenOwner
        )
        internal
        constant
        returns (uint)
    {
        return TokenTransferDelegate(
            delegateAddress
        ).getSpendable(
            tokenAddress,
            tokenOwner
        );
    }

    /// @return Amount of LRC token that can be spent by this contract.
    function getLRCSpendable(address tokenOwner)
        internal
        constant
        returns (uint)
    {
        return getSpendable(lrcTokenAddress, tokenOwner);
    }

    /// @dev verify input data&#39;s basic integrity.
    function verifyInputDataIntegrity(
        uint ringSize,
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList
        )
        internal
        constant
    {
        ErrorLib.check(
            ringSize == addressList.length,
            &quot;ring data is inconsistent - addressList&quot;
        );

        ErrorLib.check(
            ringSize == uintArgsList.length,
            &quot;ring data is inconsistent - uintArgsList&quot;
        );

        ErrorLib.check(
            ringSize == uint8ArgsList.length,
            &quot;ring data is inconsistent - uint8ArgsList&quot;
        );

        ErrorLib.check(
            ringSize == buyNoMoreThanAmountBList.length,
            &quot;ring data is inconsistent - buyNoMoreThanAmountBList&quot;
        );

        ErrorLib.check(
            ringSize + 1 == vList.length,
            &quot;ring data is inconsistent - vList&quot;
        );

        ErrorLib.check(
            ringSize + 1 == rList.length,
            &quot;ring data is inconsistent - rList&quot;
        );

        ErrorLib.check(
            ringSize + 1 == sList.length,
            &quot;ring data is inconsistent - sList&quot;
        );

        // Validate ring-mining related arguments.
        for (uint i = 0; i &lt; ringSize; i++) {
            ErrorLib.check(
                uintArgsList[i][6] &gt; 0,
                &quot;order rateAmountS is zero&quot;
            );

            ErrorLib.check(
                uint8ArgsList[i][1] &lt;= FEE_SELECT_MAX_VALUE,
                &quot;invalid order fee selection&quot;
            );
        }
    }

    /// @dev        assmble order parameters into Order struct.
    /// @return     A list of orders.
    function assembleOrders(
        uint            ringSize,
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList
        )
        internal
        constant
        returns (OrderState[])
    {
        var orders = new OrderState[](ringSize);

        for (uint i = 0; i &lt; ringSize; i++) {
            uint j = i.next(ringSize);

            var order = Order(
                addressList[i][0],
                addressList[i][1],
                addressList[j][1],
                uintArgsList[i][0],
                uintArgsList[i][1],
                uintArgsList[i][2],
                uintArgsList[i][3],
                uintArgsList[i][4],
                uintArgsList[i][5],
                buyNoMoreThanAmountBList[i],
                uint8ArgsList[i][0],
                vList[i],
                rList[i],
                sList[i]
            );

            bytes32 orderHash = calculateOrderHash(order);

            verifySignature(
                order.owner,
                orderHash,
                order.v,
                order.r,
                order.s
            );

            validateOrder(order);

            orders[i] = OrderState(
                order,
                orderHash,
                uint8ArgsList[i][1],  // feeSelection
                Rate(uintArgsList[i][6], order.amountB),
                getSpendable(order.tokenS, order.owner),
                0,   // fillAmountS
                0,   // lrcReward
                0,   // lrcFee
                0,   // splitS
                0    // splitB
            );

            ErrorLib.check(
                orders[i].availableAmountS &gt; 0,
                &quot;order spendable amountS is zero&quot;
            );
        }

        return orders;
    }

    /// @dev validate order&#39;s parameters are OK.
    function validateOrder(Order order)
        internal
        constant
    {
        ErrorLib.check(
            order.owner != address(0),
            &quot;invalid order owner&quot;
        );

        ErrorLib.check(
            order.tokenS != address(0),
            &quot;invalid order tokenS&quot;
        );

        ErrorLib.check(
            order.tokenB != address(0),
            &quot;invalid order tokenB&quot;
        );

        ErrorLib.check(
            order.amountS &gt; 0,
            &quot;invalid order amountS&quot;
        );

        ErrorLib.check(
            order.amountB &gt; 0,
            &quot;invalid order amountB&quot;
        );

        ErrorLib.check(
            order.timestamp &lt;= block.timestamp,
            &quot;order is too early to match&quot;
        );

        ErrorLib.check(
            order.timestamp &gt; cutoffs[order.owner],
            &quot;order is cut off&quot;
        );

        ErrorLib.check(
            order.ttl &gt; 0,
            &quot;order ttl is 0&quot;
        );

        ErrorLib.check(
            order.timestamp + order.ttl &gt; block.timestamp,
            &quot;order is expired&quot;
        );

        ErrorLib.check(
            order.salt &gt; 0,
            &quot;invalid order salt&quot;
        );

        ErrorLib.check(
            order.marginSplitPercentage &lt;= MARGIN_SPLIT_PERCENTAGE_BASE,
            &quot;invalid order marginSplitPercentage&quot;
        );
    }

    /// @dev Get the Keccak-256 hash of order with specified parameters.
    function calculateOrderHash(Order order)
        internal
        constant
        returns (bytes32)
    {
        return keccak256(
            address(this),
            order.owner,
            order.tokenS,
            order.tokenB,
            order.amountS,
            order.amountB,
            order.timestamp,
            order.ttl,
            order.salt,
            order.lrcFee,
            order.buyNoMoreThanAmountB,
            order.marginSplitPercentage
        );
    }

    /// @dev Verify signer&#39;s signature.
    function verifySignature(
        address signer,
        bytes32 hash,
        uint8   v,
        bytes32 r,
        bytes32 s)
        internal
        constant
    {
        address addr = ecrecover(
            keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;, hash),
            v,
            r,
            s
        );

        ErrorLib.check(signer == addr, &quot;invalid signature&quot;);
    }

}