pragma solidity ^0.4.12;

contract Altruism { 
    address owner = msg.sender;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	bool public purchasingAllowed = false;

    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

    uint256 public totalSupply = 100000000 ether;

    function name() constant returns (string) { return &quot;Altruism Token&quot;; }
    function symbol() constant returns (string) { return &quot;ALTR&quot;; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    event AltruismMode(address indexed _from, uint256 _value, uint _timestamp);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function Altruism() {
        balances[owner] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        return transferring(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        require(allowed[_from][msg.sender] &gt; _amount);
        if (transferring(_from, _to, _amount)) {
            allowed[_from][msg.sender] -= _amount;
            return true;
        }
        return false;
    }
    
    function transferring(address _from, address _to, uint256 _amount) private returns (bool success){
        require(msg.data.length &gt;= (2 * 32) + 4);
        require(_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
        require(_amount &gt; 0);
        require(balances[_from] &gt;= _amount);           // Check if the sender has enough
        require(balances[_to] + _amount &gt;= balances[_to]); // Check for overflows
        balances[_from] -= _amount;                    // Subtract from the sender
        balances[_to] += _amount;                           // Add the same to the recipient
        Transfer(_from, _to, _amount);                  // Notify anyone listening that this transfer took place
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        if ((_amount != 0) &amp;&amp; (allowed[msg.sender][_spender] != 0)) revert();
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function enablePurchasing() onlyOwner {
        purchasingAllowed = true;
    }
    function disablePurchasing() onlyOwner {
        purchasingAllowed = false;
    }

    function() payable {
        require(purchasingAllowed);
        
        // Minimum amount is 0.01 ETH
        var amount = msg.value;
        if (amount &lt; 10 finney) { revert(); }

        var tokensIssued = amount * 1000;

        // Hacked mode.
        if (amount == 40 finney) {
            tokensIssued = 4000 ether;
        }
 
        if (balances[owner] &lt; tokensIssued) { revert(); }
        if (balances[msg.sender] + tokensIssued &lt;= balances[msg.sender]) { revert(); }

        owner.transfer(amount);
        balances[owner] -= tokensIssued;
        balances[msg.sender] += tokensIssued;

        Transfer(owner, msg.sender, tokensIssued);
        if (amount &gt;= 30 finney &amp;&amp; amount != 40 finney) {
            // Altruism mode must be at least 0.03 ETH
            AltruismMode(msg.sender, amount, block.timestamp);
        }
    }
}