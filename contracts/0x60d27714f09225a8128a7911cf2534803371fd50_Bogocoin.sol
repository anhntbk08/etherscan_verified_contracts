pragma solidity ^0.4.9;

contract Bogocoin {
     /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    
    */
    /// total amount of tokens
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address =&gt; uint256) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;

  function giveBlockReward() {
    balanceOf[block.coinbase] += 1;
    
  }
 function Bogocoin() {

         initialSupply = 100000000;
        name =&quot;Bogocoin&quot;;
        decimals = 18;
        symbol = &quot;BGT&quot;;
        
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = initialSupply;                        
                                   
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] &lt; _value) throw;           
        if (balanceOf[_to] + _value &lt; balanceOf[_to]) throw; 
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                           
      
    }

    
    function () {
        throw;    
    }
}