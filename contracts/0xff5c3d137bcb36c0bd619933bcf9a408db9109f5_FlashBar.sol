pragma solidity ^0.4.16;

contract Token {

    uint256 public totalSupply;


    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value &lt;= balances[msg.sender]);
        require(balances[_to] + _value &gt; balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value &lt;= balances[_from]);
        require(_value &lt;= allowed[_from][msg.sender]);
        require(balances[_to] + _value &gt; balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract FlashBar is StandardToken {

    function () public {
        revert();
    }

    string public name = &quot;FlashBar&quot;;
    uint8 public decimals = 18;
    uint256 private supplyDecimals = 1 * 10 ** uint256(decimals);
    string public symbol = &quot;FBR&quot;;
    string public version = &#39;v0.1&#39;;
    address public founder;
    constructor  (uint256 supply) public {
        founder = msg.sender;
        totalSupply = supply * supplyDecimals;
        balances[founder] = totalSupply;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(keccak256(&quot;receiveApproval(address,uint256,address,bytes)&quot;))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }

    function approveAndCallcode(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(_extraData)) { revert(); }
        return true;
    }
}