pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b &lt;= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ownable {
    address public owner;
    function Ownable() public {
        owner =  0xf42B82D02b8f3E7983b3f7E1000cE28EC3F8C815;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract RefundVault is Ownable {
    using SafeMath for uint256;
    enum State { Active, Refunding, Closed }
    mapping (address =&gt; uint256) public deposited;
    address public wallet;
    State public state;
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    function RefundVault(address _wallet) public {
        wallet = _wallet;
        state = State.Active;
    }
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }
    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        wallet.transfer(this.balance);
        Closed();
    }
    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}

contract Gryphon is ERC20, Ownable {

    using SafeMath for uint256;

    RefundVault public vault;

    mapping(address =&gt; uint256) balances;
    mapping(address =&gt; uint256) vested;
    mapping(address =&gt; uint256) total_vested;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

    uint256 totalSupply_; // of hurtle token

    string public name = &#39;Gryphon&#39;;
    string public symbol = &#39;GXC&#39;;
    uint256 public decimals = 4;
    uint256 public initialSupply = 2000000000; //2billion

    uint256 public start;
    uint256 public duration;

    uint256 public rateICO = 910000000000000; //1 ether = 1100 GRC

    uint256 public preSaleMaxCapInWei = 2500 ether;//52400 ether;
    uint256 public preSaleRaised = 0;

    uint256 public icoSoftCapInWei = 2500 ether;//52400 ether; //1 million gbp
    uint256 public icoHardCapInWei = 122400 ether; //12 million gbp
    uint256 public icoRaised = 0;

    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;
    uint256 public icoStartTimestamp;
    uint256 public icoEndTimestamp;

    uint256 public presaleTokenLimit;
    uint256 public icoTokenLimit;

    uint256 public investorCount;

    enum State {Unknown, Preparing, PreSale, ICO, Success, Failure, PresaleFinalized, ICOFinalized}

    State public crowdSaleState;

    modifier nonZero() {
        require(msg.value &gt; 0);
        _;
    }

    function Gryphon() public {

        owner = 0xf42B82D02b8f3E7983b3f7E1000cE28EC3F8C815;
        vault = new RefundVault(0x6cD6B03D16E4BE08159412a7E290F1EA23446Bf2); //address of wallet in which process will go in case of success

        totalSupply_ = initialSupply*(10**decimals); //The total supply defined in base token

        balances[owner] = totalSupply_;

        presaleStartTimestamp = 1525046400;
        presaleEndTimestamp = presaleStartTimestamp + 30 * 1 days;

        icoStartTimestamp = presaleEndTimestamp + 1 days;
        icoEndTimestamp = icoStartTimestamp + 90 * 1 days;

        crowdSaleState = State.Preparing;

        start = 1525046400;
        duration = 23328000;
    }

    function () nonZero payable {
        enter();
    }

    function enter() public nonZero payable {
        //test = msg.value;
        if(isPreSalePeriod()) {

            if(crowdSaleState == State.Preparing) {
                crowdSaleState = State.PreSale;
            }

            buyTokens(msg.sender, msg.value);
        }
        else if (isICOPeriod()) {
            if(crowdSaleState == State.PresaleFinalized) {
                crowdSaleState = State.ICO;
            }

            buyTokens(msg.sender, msg.value);
        } else {

            revert();
        }
    }

    function buyTokens(address _recipient, uint256 _value) internal nonZero returns (bool success) {
        uint256 boughtTokens = calculateTokens(_value);
        require(boughtTokens != 0);
        boughtTokens = boughtTokens*(10**decimals);

        if(balanceOf(_recipient) == 0) {
            investorCount++;
        }

        if(isCrowdSaleStatePreSale()) {
            transferTokens(_recipient, boughtTokens);
            vault.deposit.value(_value)(_recipient);
            preSaleRaised = preSaleRaised.add(_value);
            return true;
        } else if (isCrowdSaleStateICO()) {
            transferTokens(_recipient, boughtTokens);
            vault.deposit.value(_value)(_recipient);
            icoRaised = icoRaised.add(_value);
            return true;
        }
    }

    function transferTokens(address _recipient, uint256 tokens_in_cents) internal returns (bool) {
        require(
            tokens_in_cents &gt; 0
            &amp;&amp; _recipient != owner
            &amp;&amp; tokens_in_cents &lt; balances[owner]
        );

        balances[owner] = balances[owner].sub(tokens_in_cents);

        //add vesting here
        balances[_recipient] = balances[_recipient].add(tokens_in_cents);
        getVested(_recipient);

        Transfer(owner, _recipient, tokens_in_cents); //actual function that does the transfer
        return true;
    }

    function getVested(address _beneficiary) public returns (uint256) {
        require(balances[_beneficiary]&gt;0);
        if (_beneficiary == owner){

            vested[owner] = balances[owner];
            total_vested[owner] = balances[owner];

        } else if (block.timestamp &lt; start) {

            vested[_beneficiary] = 0;
            total_vested[_beneficiary] = 0;

        } else if (block.timestamp &gt;= start.add(duration)) {

            total_vested[_beneficiary] = balances[_beneficiary];
            vested[_beneficiary] = balances[_beneficiary];

        } else {

            uint vested_now = balances[_beneficiary].mul(block.timestamp.sub(start)).div(duration);
            if(total_vested[_beneficiary]==0){
                total_vested[_beneficiary] = vested_now;

            }
            if(vested_now &gt; total_vested[_beneficiary]){
                vested[_beneficiary] = vested[_beneficiary].add(vested_now.sub(total_vested[_beneficiary]));
                total_vested[_beneficiary] = vested_now;
            }
        }
        return vested[_beneficiary];
    }

    function transfer(address _to, uint256 _tokens_in_cents) public returns (bool) {
        require(_tokens_in_cents &gt; 0);
        require(_to != msg.sender);
        getVested(msg.sender);
        require(balances[msg.sender] &gt;= _tokens_in_cents);
        require(vested[msg.sender] &gt;= _tokens_in_cents);

        if(balanceOf(_to) == 0) {  //increase invester count if new invester
            investorCount++;
        }

        balances[msg.sender] = balances[msg.sender].sub(_tokens_in_cents);
        vested[msg.sender] = vested[msg.sender].sub(_tokens_in_cents);
        balances[_to] = balances[_to].add(_tokens_in_cents);

        if(balanceOf(msg.sender) == 0) { //update invester count
            investorCount=investorCount-1;
        }

        //TODO: increment raised values here

        Transfer(msg.sender, _to, _tokens_in_cents);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _tokens_in_cents) public returns (bool success) {
        require(_tokens_in_cents &gt; 0);
        require(_from != _to);
        getVested(_from);
        require(balances[_from] &gt;= _tokens_in_cents);
        require(vested[_from] &gt;= _tokens_in_cents);
        require(allowed[_from][msg.sender] &gt;= _tokens_in_cents);

        if(balanceOf(_to) == 0) {  //increase invester count if new invester
            investorCount++;
        }

        balances[_from] = balances[_from].sub(_tokens_in_cents);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens_in_cents);
        vested[_from] = vested[_from].sub(_tokens_in_cents);

        balances[_to] = balances[_to].add(_tokens_in_cents);

        if(balanceOf(_from) == 0) { //update invester count
            investorCount=investorCount-1;
        }

        Transfer(_from, _to, _tokens_in_cents);
        return true;
    }

    function approve(address _spender, uint256 _tokens_in_cents) returns (bool success) {
        require(vested[msg.sender] &gt;= _tokens_in_cents);
        allowed[msg.sender][_spender] = _tokens_in_cents;
        Approval(msg.sender, _spender, _tokens_in_cents);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function calculateTokens(uint256 _amount) internal returns (uint256 tokens){
        if(crowdSaleState == State.Preparing &amp;&amp; isPreSalePeriod()) {
            crowdSaleState = State.PreSale;
        }
        if(isCrowdSaleStatePreSale()) {
            tokens = _amount.div(rateICO);
        } else if (isCrowdSaleStateICO()) {
            tokens = _amount.div(rateICO);
        } else {
            tokens = 0;
        }
    }

    function getRefund(address _recipient) public returns (bool){
        require(crowdSaleState == State.Failure);
        require(refundedAmount(_recipient));
        vault.refund(_recipient);
        return true;
    }

    function refundedAmount(address _recipient) internal returns (bool) {
        require(balances[_recipient] != 0);
        balances[_recipient] = 0;
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address a) public view returns (uint256 balance) {
        return balances[a];
    }


    /////////////////////
    // State Functions //
    /////////////////////

    /** Check the state of the Contract, if in Pre Sale
      * @return bool  Return true if the contract is in Pre Sale
      */

    function isCrowdSaleStatePreSale() public constant returns (bool) {
        return crowdSaleState == State.PreSale;
    }

    /** Check the state of the Contract, if in ICO
      * @return bool  Return true if the contract is in ICO
      */

    function isCrowdSaleStateICO() public constant returns (bool) {
        return crowdSaleState == State.ICO;
    }

    /** Check if the Pre Sale Period is still ON
      * @return bool  Return true if the contract is in Pre Sale Period
      */

    function isPreSalePeriod() public constant returns (bool) {
        if(preSaleRaised &gt; preSaleMaxCapInWei || now &gt;= presaleEndTimestamp) {
            crowdSaleState = State.PresaleFinalized;
            //icoStartTimestamp = now.sub(10); //CONFIRM
            return false;
        } else {
            return now &gt; presaleStartTimestamp;
        }
    }

    /** Check if the ICO is in the Sale period or not
      * @return bool  Return true if the contract is in ICO Period
      */

    function isICOPeriod() public constant returns (bool) {
        if (icoRaised &gt; icoHardCapInWei || now &gt;= icoEndTimestamp){
            crowdSaleState = State.ICOFinalized;
            return false;
        } else {
            return now &gt; icoStartTimestamp;
        }
    }

    // Called by the owner of the contract to close the Sale
    function endCrowdSale() public onlyOwner {
        require(now &gt;= icoEndTimestamp || icoRaised &gt;= icoSoftCapInWei);
        if(icoRaised &gt;= icoSoftCapInWei){
            crowdSaleState = State.Success;
            vault.close(); //send funds to owner
        } else {
            crowdSaleState = State.Failure;
            vault.enableRefunds(); //allow people to get refund
        }
    }

    /////////////////////////////////////////
    // Fetch some statistics about the ICO //
    /////////////////////////////////////////

    function getInvestorCount() public constant returns (uint256) {
        return investorCount;
    }

    function getPresaleRaisedAmount() public constant returns (uint256) {
        return preSaleRaised;
    }

    function getICORaisedAmount() public constant returns (uint256) {
        return icoRaised;
    }

}