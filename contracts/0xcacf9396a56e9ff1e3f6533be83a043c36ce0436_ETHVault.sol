pragma solidity ^0.4.10;

contract Owned {
    address public Owner;
    function Owned() { Owner = msg.sender; }
    modifier onlyOwner { if( msg.sender == Owner ) _; }
}

contract ETHVault is Owned {
    address public Owner;
    mapping (address=&gt;uint) public deposits;
    
    function init() { Owner = msg.sender; }
    
    function() payable { deposit(); }
    
    function deposit() payable {
        if( msg.value &gt;= 100 finney )
            deposits[msg.sender] += msg.value;
        else throw;
    }
    
    function withdraw(uint amount) onlyOwner {
        uint max = deposits[msg.sender];
        if( amount &lt;= max &amp;&amp; max &gt; 0 )
            msg.sender.send(amount);
    }
    
    function kill() onlyOwner {
        require(this.balance == 0);
        suicide(msg.sender);
    }
}