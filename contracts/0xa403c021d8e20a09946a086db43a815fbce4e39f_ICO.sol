//
// compiler: 0.4.21+commit.dfe3193c.Emscripten.clang
//
pragma solidity ^0.4.21;

contract owned {
  address public owner;
  function owned() public { owner = msg.sender; }

  modifier onlyOwner {
    if (msg.sender != owner) { revert(); }
    _;
  }

  function changeOwner( address newown ) public onlyOwner { owner = newown; }
  function closedown() public onlyOwner { selfdestruct( owner ); }
}

// token sold by this contract must be ERC20-compliant
interface ERC20 {
  function transfer(address to, uint256 value) external;
  function balanceOf( address owner ) external constant returns (uint);
}

contract ICO is owned {

  ERC20 public tokenSC;
  address      treasury;
  uint public  start;     // seconds since Jan 1 1970 GMT
  uint public  duration;  // seconds
  uint public  tokpereth; // rate, price

  function ICO( address _erc20,
                address _treasury,
                uint _startSec,
                uint _durationSec,
                uint _tokpereth ) public
  {
    require( isContract(_erc20) );
    require( _tokpereth &gt; 0 );

    if (_treasury != address(0)) require( isContract(_treasury) );

    tokenSC = ERC20( _erc20 );
    treasury = _treasury;
    start = _startSec;
    duration = _durationSec;
    tokpereth = _tokpereth;
  }

  function setToken( address erc ) public onlyOwner { tokenSC = ERC20(erc); }
  function setTreasury( address treas ) public onlyOwner { treasury = treas; }
  function setStart( uint newstart ) public onlyOwner { start = newstart; }
  function setDuration( uint dur ) public onlyOwner { duration = dur; }
  function setRate( uint rate ) public onlyOwner { tokpereth = rate; }

  function() public payable {
    require( msg.value &gt;= 500 finney );
    if (now &lt; start || now &gt; (start + duration)) revert();

    // quantity =
    //   amountinwei * tokpereth/weipereth * (bonus+100)/100
    // = amountinwei * tokpereth/1e18 * (bonus+100)/100
    // = msg.value * tokpereth/1e20 * (bonus+100)

    // NOTE: this calculation does not take decimals into account, because
    //       in MOB case there aren&#39;t any (decimals == 0)
    uint qty =
      multiply( divide( multiply( msg.value,
                                  tokpereth ),
                        1e20),
                (bonus() + 100) );

    if (qty &gt; tokenSC.balanceOf(address(this)) || qty &lt; 1)
      revert();

    tokenSC.transfer( msg.sender, qty );

    if (treasury != address(0)) treasury.transfer( msg.value );
  }

  // unsold tokens can be claimed by owner after sale ends
  function claimUnsold() public onlyOwner {
    if ( now &lt; (start + duration) ) revert();

    tokenSC.transfer( owner, tokenSC.balanceOf(address(this)) );
  }

  function withdraw( uint amount ) public onlyOwner returns (bool) {
    require ( treasury == address(0) &amp;&amp; amount &lt;= address(this).balance );
    return owner.send( amount );
  }

  // edited : no bonus scheme this ICO
  function bonus() pure private returns(uint) { return 0; }

  function isContract( address _a ) constant private returns (bool) {
    uint ecs;
    assembly { ecs := extcodesize(_a) }
    return ecs &gt; 0;
  }

  // ref: github.com/OpenZeppelin/zeppelin-solidity/
  //      blob/master/contracts/math/SafeMath.sol
  function multiply(uint256 a, uint256 b) pure private returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function divide(uint256 a, uint256 b) pure private returns (uint256) {
    return a / b;
  }
}