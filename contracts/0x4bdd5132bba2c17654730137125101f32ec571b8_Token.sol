pragma solidity ^0.4.23;


contract Owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external; }


contract TokenBase is Owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    uint public tokenUnit = 10 ** uint(decimals);
    uint public kUnit = 1000 * tokenUnit;
    uint public foundingTime;

    mapping (address =&gt; uint) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);

    constructor() public {
        foundingTime = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] &gt;= _value);
        require(balanceOf[_to] + _value &gt; balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value &lt;= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}



contract Token is TokenBase {
    uint public initialSupply = 100*10**26;
    uint public reserveSupply = 0;

    constructor() public {
        name = &quot;EX&quot;;
        symbol = &quot;EX&quot;;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function releaseReserve(uint value) onlyOwner public {
        require(reserveSupply &gt;= value);
        balanceOf[owner] += value;
        totalSupply += value;
        reserveSupply -= value;
        emit Transfer(0, this, value);
        emit Transfer(this, owner, value);
    }

}