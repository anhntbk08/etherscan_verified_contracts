pragma solidity ^0.4.16;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract MEMESCrowdsale {
    
    Token public tokenReward;
    address public creator;
    address public owner = 0x398626cc0a59e8D58E536dBCe67a1D4Ac9C4609b;

    uint256 public price;
    uint256 public startDate;
    uint256 public endDate;

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    event FundTransfer(address backer, uint amount, bool isContribution);

    function MEMESCrowdsale() public {
        creator = msg.sender;
        startDate = 1519862400;
        endDate = 1527894000;
        price = 5000;
        tokenReward = Token(0xF3CdCd6f66BebDB6C7D33E3ef1Bf38Ae0Cefe3C6);
    }

    function setOwner(address _owner) isCreator public {
        owner = _owner;      
    }

    function setCreator(address _creator) isCreator public {
        creator = _creator;      
    }

    function setStartDate(uint256 _startDate) isCreator public {
        startDate = _startDate;      
    }

    function setEndtDate(uint256 _endDate) isCreator public {
        endDate = _endDate;      
    }

    function setPrice(uint256 _price) isCreator public {
        price = _price;      
    }

    function setToken(address _token) isCreator public {
        tokenReward = Token(_token);      
    }

    function sendToken(address _to, uint256 _value) isCreator public {
        tokenReward.transfer(_to, _value);      
    }

    function () payable public {
        require(msg.value &gt; 0);
        require(now &gt; startDate);
        require(now &lt; endDate);
	    uint amount = msg.value * price;
        tokenReward.transfer(msg.sender, amount);
        FundTransfer(msg.sender, amount, true);
        owner.transfer(msg.value);
    }
}