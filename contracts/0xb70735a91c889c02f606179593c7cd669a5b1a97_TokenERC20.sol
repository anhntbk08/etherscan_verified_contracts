pragma solidity ^0.4.16;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;
    //AnimatedProject
    address public owner;
    uint public exrate; //exchange radio 
    bool public ifEndGetting;
    //AnimatedProject
    uint256 public bonusPool;
    mapping (address =&gt; uint8) public bonusTimes; //record the times address has taken
    uint8 public bonusNum;  //times of bonus distribution
    uint256[30] public bonusPer; //ETH bonus per token, max 30 times


    // This creates an array with all balances
    mapping (address =&gt; uint256) public balanceOf;
    mapping (address =&gt; mapping (address =&gt; uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint exchangeRate
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        //AnimatedProject
        owner =  msg.sender;
        exrate = exchangeRate;

    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] &gt;= _value);
        // Check for overflows
        require(balanceOf[_to] + _value &gt; balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value &lt;= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    //AnimatedProject: Getting Token From Owner by ETH
    function getToken  () public payable{
        uint256 exvalue = msg.value;

        if (!ifEndGetting &amp;&amp;
            msg.sender != owner &amp;&amp; 
            exvalue &gt; 0 &amp;&amp; 
            balanceOf[owner] &gt;= exvalue * exrate){

            //send ETH to the owner, send token to the sender
            if (owner.send(exvalue)) {
                _transfer(owner, msg.sender, exvalue * exrate);
            } 
        }
    }

    //AnimatedProject: Destroy Contract Before Publiced
    function owner_testEnd  () public {
        if (msg.sender == owner &amp;&amp;
            balanceOf[owner] &gt; totalSupply * 4/5){
            selfdestruct(owner);
        }
    }

    //AnimatedProject: End Getting Token
    function owner_endGetting () public {
        ifEndGetting = true;
    }

    //AnimatedProject: Send Bonus To Contract
    function owner_bonusSend () public payable {
        if (msg.sender == owner &amp;&amp;
            bonusNum &lt; 30){

            bonusPool += msg.value;
            bonusNum ++;
            bonusPer[bonusNum] = msg.value/totalSupply;
        }
    }

    //AnimatedProject: Take Bonus By Token
    function bonusTake () public {

        if (bonusTimes[msg.sender] &lt; bonusNum){

            uint256 sendCount;
            address addrs = msg.sender;
            
            for (uint8 i = bonusTimes[addrs]+1; i &lt;=bonusNum; i++) {
                sendCount += ( bonusPer[i] * balanceOf[addrs] );
            }

            if (bonusPool &gt;= sendCount) {
                if (addrs.send(sendCount)){
                    bonusPool -= sendCount;
                    bonusTimes[addrs] ++;
                }
            }
        }
    }

}