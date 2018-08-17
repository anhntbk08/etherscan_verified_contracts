pragma solidity ^0.4.24;

contract OneToken {
    uint256 public currentHodlerId;
    address public currentHodler;
    address[] public previousHodlers;
    
    string[] public messages;
    uint256 public price;
    
    event Purchased(
        uint indexed _buyerId,
        address _buyer
    );

    mapping (address =&gt; uint) public balance;

    constructor() public {
        currentHodler = msg.sender;
        currentHodlerId = 0;
        messages.push(&quot;Sky is the limit!&quot;);
        price = 8 finney;
        emit Purchased(currentHodlerId, currentHodler);
    }

    function buy(string message) public payable returns (bool) {
        require (msg.value &gt;= price);
        
        if (msg.value &gt; price) {
            balance[msg.sender] += msg.value - price;
        }
        uint256 previousHodlersCount = previousHodlers.length;
        for (uint256 i = 0; i &lt; previousHodlersCount; i++) {
            balance[previousHodlers[i]] += (price * 8 / 100) / previousHodlersCount;
        }
        balance[currentHodler] += price * 92 / 100;

        price = price * 120 / 100;  
        previousHodlers.push(currentHodler);
        messages.push(message);
        
        currentHodler = msg.sender;
        currentHodlerId = previousHodlersCount + 1;
        emit Purchased(currentHodlerId, currentHodler);
    }

    function withdraw() public {
        uint amount = balance[msg.sender];
        balance[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}