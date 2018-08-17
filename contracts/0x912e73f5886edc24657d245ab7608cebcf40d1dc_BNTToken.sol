pragma solidity ^0.4.16;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract BNTToken {
    /* Public variables of the BNT Token */
    string public standard = &#39;Token 1.1&#39;;
    string public name = &#39;BeniNiciThomasToken&#39;;
    string public symbol = &#39;BNTT&#39;;
    uint8 public decimals = 4;
    uint256 public totalSupply = 10000;

    /* Creates an array with all balances */
    mapping (address =&gt; uint256) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;

    /* Generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to me */
    function BNTToken() {
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] &lt; _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value &lt; balanceOf[_to]) revert(); // Check for overflows
        balanceOf[msg.sender] -= _value;                        // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                      // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens on my behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        if ((_value != 0) &amp;&amp; (allowance[msg.sender][_spender] != 0)) revert();
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[_from] &lt; _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value &lt; balanceOf[_to]) revert();  // Check for overflows
        if (_value &gt; allowance[_from][msg.sender]) revert();     // Check allowance
        balanceOf[_from] -= _value;                              // Subtract from the sender
        balanceOf[_to] += _value;                                // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

	/* Burn BNTTs by User */
    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] &lt; _value) revert();            // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                         // Subtract from the sender
        totalSupply -= _value;                                   // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

	/* Burn BNTTs from Users */
    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balanceOf[_from] &lt; _value) revert();                // Check if the sender has enough
        if (_value &gt; allowance[_from][msg.sender]) revert();    // Check allowance
        balanceOf[_from] -= _value;                             // Subtract from the sender
        totalSupply -= _value;                                  // Updates totalSupply
        Burn(_from, _value);
        return true;
    }
}