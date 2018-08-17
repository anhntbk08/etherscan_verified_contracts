pragma solidity ^0.4.23;

/*

  BASIC ERC20 Sale Contract

  Create this Sale contract first!

     Sale(address ethwallet)   // this will send the received ETH funds to this address


  @author Hunter Long
  @repo https://github.com/hunterlong/ethereum-ico-contract

*/
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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


contract ERC20 {
  function sale(address to, uint256 value);
}


contract Sale {
    uint public preSaleEnd = 1527120000; //05/24/2018 @ 12:00am (UTC)
    uint public saleEnd1 = 1528588800; //06/10/2018 @ 12:00am (UTC)
    uint public saleEnd2 = 1529971200; //06/26/2018 @ 12:00am (UTC)
    uint public saleEnd3 = 1531267200; //07/11/2018 @ 12:00am (UTC)
    uint public saleEnd4 = 1532476800; //07/25/2018 @ 12:00am (UTC)

    uint256 public saleExchangeRate1 = 17500;
    uint256 public saleExchangeRate2 = 10000;
    uint256 public saleExchangeRate3 = 8750;
    uint256 public saleExchangeRate4 = 7778;
    uint256 public saleExchangeRate5 = 7368;
    
    uint256 public volumeType1 = 1429 * 10 ** 16; //14.29 eth
    uint256 public volumeType2 = 7143 * 10 ** 16;
    uint256 public volumeType3 = 14286 * 10 ** 16;
    uint256 public volumeType4 = 42857 * 10 ** 16;
    uint256 public volumeType5 = 71429 * 10 ** 16;
    uint256 public volumeType6 = 142857 * 10 ** 16;
    uint256 public volumeType7 = 428571 * 10 ** 16;
    
    uint256 public minEthValue = 10 ** 15; // 0.001 eth
    
    using SafeMath for uint256;
    uint256 public maxSale;
    uint256 public totalSaled;
    ERC20 public Token;
    address public ETHWallet;

    address public creator;

    mapping (address =&gt; uint256) public heldTokens;
    mapping (address =&gt; uint) public heldTimeline;

    event Contribution(address from, uint256 amount);

    function Sale(address _wallet, address _token_address) {
        maxSale = 316906850 * 10 ** 8; 
        ETHWallet = _wallet;
        creator = msg.sender;
        Token = ERC20(_token_address);
    }

    

    function () payable {
        buy();
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        buy();
    }
    
    
    function buy() internal {
        require(msg.value&gt;=minEthValue);
        require(now &lt; saleEnd4);
        
        uint256 amount;
        uint256 exchangeRate;
        if(now &lt; preSaleEnd) {
            exchangeRate = saleExchangeRate1;
        } else if(now &lt; saleEnd1) {
            exchangeRate = saleExchangeRate2;
        } else if(now &lt; saleEnd2) {
            exchangeRate = saleExchangeRate3;
        } else if(now &lt; saleEnd3) {
            exchangeRate = saleExchangeRate4;
        } else if(now &lt; saleEnd4) {
            exchangeRate = saleExchangeRate5;
        }
        
        amount = msg.value.mul(exchangeRate).div(10 ** 10);
        
        if(msg.value &gt;= volumeType7) {
            amount = amount * 180 / 100;
        } else if(msg.value &gt;= volumeType6) {
            amount = amount * 160 / 100;
        } else if(msg.value &gt;= volumeType5) {
            amount = amount * 140 / 100;
        } else if(msg.value &gt;= volumeType4) {
            amount = amount * 130 / 100;
        } else if(msg.value &gt;= volumeType3) {
            amount = amount * 120 / 100;
        } else if(msg.value &gt;= volumeType2) {
            amount = amount * 110 / 100;
        } else if(msg.value &gt;= volumeType1) {
            amount = amount * 105 / 100;
        }
        
        uint256 total = totalSaled + amount;
        
        require(total&lt;=maxSale);
        
        totalSaled = total;
        
        ETHWallet.transfer(msg.value);
        Token.sale(msg.sender, amount);
        Contribution(msg.sender, amount);
    }
    
    
    


    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }



}