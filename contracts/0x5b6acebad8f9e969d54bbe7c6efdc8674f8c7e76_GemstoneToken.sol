pragma solidity ^0.4.16;
/*-------------------------------------------------------------------------*/
 /*
  * Website	: https://gemstonetokenblog.blogspot.com
  * Email	: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1c7b79716f6873727968737779725c7b717d7570327f7371">[email&#160;protected]</a>
 */
/*-------------------------------------------------------------------------*/
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
/*-------------------------------------------------------------------------*/
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner == 0x0) throw;
        owner = newOwner;
    }
}
/*-------------------------------------------------------------------------*/
/**
 * Overflow aware uint math functions.
 */
contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b &lt;= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c&gt;=a &amp;&amp; c&gt;=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}
/*-------------------------------------------------------------------------*/
contract GemstoneToken is owned, SafeMath {
	
	string 	public EthernetCashWebsite	= &quot;https://ethernet.cash&quot;;
	address public EthernetCashAddress 	= this;
	address public creator 				= msg.sender;
    string 	public name 				= &quot;Gemstone Token&quot;;
    string 	public symbol 				= &quot;GST&quot;;
    uint8 	public decimals 			= 18;											    
    uint256 public totalSupply 			= 19999999986000000000000000000;
    uint256 public buyPrice 			= 18000000;
	uint256 public sellPrice 			= 18000000;
   	
    mapping (address =&gt; uint256) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;
	mapping (address =&gt; bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);				
    event FundTransfer(address backer, uint amount, bool isContribution);
     // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
	event FrozenFunds(address target, bool frozen);
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function GemstoneToken() public {
        balanceOf[msg.sender] = totalSupply;    											
		creator = msg.sender;
    }
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] &gt;= _value);
        // Check for overflows
        require(balanceOf[_to] + _value &gt;= balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    /// @notice Buy tokens from contract by sending ether
    function () payable internal {
        uint amount = msg.value * buyPrice ; 
		uint amountRaised;
		uint bonus = 0;
		
		bonus = getBonus(amount);
		amount = amount +  bonus;
		
		//amount = now ;
		
        require(balanceOf[creator] &gt;= amount);               				
        require(msg.value &gt; 0);
		amountRaised = safeAdd(amountRaised, msg.value);                    
		balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);     
        balanceOf[creator] = safeSub(balanceOf[creator], amount);           
        Transfer(creator, msg.sender, amount);               				
        creator.transfer(amountRaised);
    }
	
	/// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

	
	/**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
	
    /// @notice `freeze? Prevent | Allow` `target` from sending &amp; receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
	
	
	/**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] &gt;= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
	
	/**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] &gt;= _value);                // Check if the targeted balance is enough
        require(_value &lt;= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
	
	function getBonus(uint _amount) constant private returns (uint256) {
        
		if(now &gt;= 1524873600 &amp;&amp; now &lt;= 1527551999) { 
            return _amount * 50 / 100;
        }
		
		if(now &gt;= 1527552000 &amp;&amp; now &lt;= 1530316799) { 
            return _amount * 40 / 100;
        }
		
		if(now &gt;= 1530316800 &amp;&amp; now &lt;= 1532995199) { 
            return _amount * 30 / 100;
        }
		
		if(now &gt;= 1532995200 &amp;&amp; now &lt;= 1535759999) { 
            return _amount * 20 / 100;
        }
		
		if(now &gt;= 1535760000 &amp;&amp; now &lt;= 1538438399) { 
            return _amount * 10 / 100;
        }
		
        return 0;
    }
	
	/// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(this.balance &gt;= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }
	
 }
/*-------------------------------------------------------------------------*/