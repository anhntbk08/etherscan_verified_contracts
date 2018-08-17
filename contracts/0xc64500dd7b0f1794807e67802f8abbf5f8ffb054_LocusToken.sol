pragma solidity ^0.4.21;

interface tokenRecipient { function receiveApproval(address _from, uint _value, address _token, bytes _extraData) external; }

contract LocusToken {
    
    address public tokenOwner;
    
    string public constant name = &quot;Locus Chain&quot;;
    string public constant symbol = &quot;LOCUS&quot;;
    
    uint8 public constant decimals = 18;
    uint public totalSupply;
    
    uint internal constant initialSupply = 7000000000 * (10 ** uint(decimals));
    
    mapping(address =&gt; uint) public balanceOf;
    mapping(address =&gt; mapping(address =&gt; uint)) internal allowed;
	
	function balanceOfToken(address _owner) public view returns(uint) {
	    return balanceOf[_owner];
	}
    
    function allowance(address _owner, address _spender) public view returns(uint) {
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
    
    function LocusToken() public {
        tokenOwner = msg.sender;
        totalSupply = initialSupply;
        balanceOf[tokenOwner] = totalSupply;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(_value &lt;= balanceOf[_from]);
        require(balanceOf[_to] + _value &gt; balanceOf[_to]);
        uint prevBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == prevBalances);
    }
    
    function transfer(address _to, uint _value) public returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns(bool) {
        require(_value &lt;= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns(bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if(approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    function burn(uint _value) public returns(bool) {
        require(_value &lt;= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }  
}