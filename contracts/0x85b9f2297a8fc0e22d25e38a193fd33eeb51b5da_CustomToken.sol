pragma solidity ^0.4.19;

contract BaseToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address =&gt; uint256) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] &gt;= _value);
        require(balanceOf[_to] + _value &gt; balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value &lt;= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract ICOToken is BaseToken {
    // 1 ether = icoRatio token
    uint256 public icoRatio;
    uint256 public icoEndtime;
    address public icoSender;
    address public icoHolder;

    event ICO(address indexed from, uint256 indexed value, uint256 tokenValue);
    event Withdraw(address indexed from, address indexed holder, uint256 value);

    modifier onlyBefore() {
        if (now &gt; icoEndtime) {
            revert();
        }
        _;
    }

    function() public payable onlyBefore {
        uint256 tokenValue = (msg.value * icoRatio * 10 ** uint256(decimals)) / (1 ether / 1 wei);
        if (tokenValue == 0 || balanceOf[icoSender] &lt; tokenValue) {
            revert();
        }
        _transfer(icoSender, msg.sender, tokenValue);
        ICO(msg.sender, msg.value, tokenValue);
    }

    function withdraw() {
        uint256 balance = this.balance;
        icoHolder.transfer(balance);
        Withdraw(msg.sender, icoHolder, balance);
    }
}

contract CustomToken is BaseToken, ICOToken {
    function CustomToken() public {
        totalSupply = 200000000000000000000000000;
        balanceOf[0xa5791f4e7bf0ec01620317cf9f135325a5b47404] = totalSupply;
        name = &#39;Supercomputing&#39;;
        symbol = &#39;scp&#39;;
        decimals = 18;
        icoRatio = 15000;
        icoEndtime = 1546268400;
        icoSender = 0x1923c58bac8062ba78d198c50f8c5ec63b52f44c;
        icoHolder = 0xa5791f4e7bf0ec01620317cf9f135325a5b47404;
    }
}