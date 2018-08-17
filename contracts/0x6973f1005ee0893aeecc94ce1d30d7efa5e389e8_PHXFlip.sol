pragma solidity ^0.4.20;

/*
    ____
   /\&#39; .\    _____
  /: \___\  / .  /\
  \&#39; / . / /____/..\
   \/___/  \&#39;  &#39;\  /
            \&#39;__&#39;\/

 Developer:  TechnicalRise
 
 ** Updated with low (3%) house edge
 ** and contract events
 
 *   &#169; 2018 TechnicalRise.  Written in March 2018.  
 *   All rights reserved.  Do not copy, adapt, or otherwise use without permission.
 *   https://www.reddit.com/user/TechnicalRise/
 
*/

contract PHXReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract PHXInterface {
    function balanceOf(address who) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
}

contract PHXFlip is PHXReceivingContract {

    address public constant PHXTKNADDR = 0x14b759A158879B133710f4059d32565b4a66140C;
    PHXInterface public PHXTKN;
    
    event result(address indexed _roller, uint _wager, uint _payout, uint indexed _rollednumber);

	function PHXFlip() public {
	    PHXTKN = PHXInterface(PHXTKNADDR); // Initialize the PHX Contract
	}
	
	function tokenFallback(address _from, uint _value, bytes _data) public {
	  // Note that msg.sender is the Token Contract Address
	  // and &quot;_from&quot; is the sender of the tokens
	  require(_humanSender(_from)); // Check that this is a non-contract sender
	  require(_phxToken(msg.sender));
	  
	  uint _balance = PHXTKN.balanceOf(this);
	  uint _possibleWinnings = 2 * _value;
	  uint _rollednumber = _prand(100) + 1;
	  // This doesn&#39;t require the PHX Balance to be greater than double the bet
	  // So check the contract&#39;s PHX Balance before wagering!
	  if(_rollednumber &lt; 48) { // i.e. 1-47 wins, 48-100 loses
	      if(_balance &gt;= _possibleWinnings) {
	          PHXTKN.transfer(_from, _possibleWinnings);
	          emit result(_from, _value, _possibleWinnings, _rollednumber);
	      } else {
	          PHXTKN.transfer(_from,_balance);
	          emit result(_from, _value, _balance, _rollednumber);
	      }
	  } else {
	      // And if you don&#39;t win, you get a Rise so that you know you lost
	      PHXTKN.transfer(_from, 1);
	      emit result(_from, _value, 1, _rollednumber);
	  }
    }
    
    // This is a supercheap psuedo-random number generator
    // that relies on the fact that &quot;who&quot; will mine and &quot;when&quot; they will
    // mine is random.  This is obviously vulnerable to &quot;inside the block&quot;
    // attacks where someone writes a contract mined in the same block
    // and calls this contract from it -- but we don&#39;t accept transactions
    // from foreign contracts, lessening that risk
    function _prand(uint _modulo) private view returns (uint) {
        uint seed1 = uint(block.coinbase); // Get Miner&#39;s Address
        uint seed2 = now; // Get the timestamp
        return uint(keccak256(seed1, seed2)) % _modulo;
    }
    
    function _phxToken(address _tokenContract) private pure returns (bool) {
        return _tokenContract == PHXTKNADDR; // Returns &quot;true&quot; of this is the PHX Token Contract
    }
    
    // Determine if the &quot;_from&quot; address is a contract
    function _humanSender(address _from) private view returns (bool) {
      uint codeLength;
      assembly { codeLength := extcodesize(_from)  }
      return (codeLength == 0); // If this is &quot;true&quot; sender is most likely  a Wallet
    }
}