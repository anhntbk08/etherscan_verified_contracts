pragma solidity ^0.4.18;

contract MyToken {

    string public name = &quot;Test&quot;;
    string public symbol = &quot;TEST&quot;;
    uint8 public decimals = 8;
    uint256 public initialSupply = 200000000;
    uint256 public totalSupply;
    
    mapping (address =&gt; uint256) public balanceOf;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken() public {
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] &gt;= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value &gt;= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
    }
}