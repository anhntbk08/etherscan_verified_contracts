contract Partner {
    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _RequestedTokens);
}

contract MNY {
    string public name = &quot;Monkey&quot;;
    uint8 public decimals = 18;
    string public symbol = &quot;MNY&quot;;

    address public _owner;
    address public _dev = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;
    address public _devFeesAddr;
    uint256 public _tokePerEth = 4877000000000000000000;
    bool public _coldStorage = true;
    bool public _receiveEth = false;

    // fees vars - added for future extensibility purposes only
    bool _feesEnabled = false;
    bool _payFees = false;
    uint256 _fees;  // the calculation expects % * 100 (so 10% is 1000)
    uint256 _lifeVal = 0;
    uint256 _feeLimit = 0;
    uint256 _devFees = 0;

    uint256 public _totalSupply = 1000000928 * 1 ether;
    uint256 public _circulatingSupply = 0;
    uint256 public _frozenTokens = 0;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Exchanged(address indexed _from, address indexed _to, uint _value);

    // Storage
    mapping (address =&gt; uint256) public balances;

    // list of contract addresses that this contract can request tokens from
    // use add/remove functions
    mapping (address =&gt; bool) public exchangePartners;

    // permitted exch partners and associated token rates
    // rate is X target tokens per Y incoming so newTokens = Tokens/Rate
    mapping (address =&gt; uint256) public exchangeRates;

    function MNY() {
        _owner = msg.sender;
        preMine();
    }

    function preMine() internal {

    }

    function transfer(address _to, uint _value, bytes _data) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] &gt;= _value);

        if(_to == address(this)) {
            // WARNING: if you transfer tokens back to the contract you will lose them
            // use the exchange function to exchange with approved partner contracts
            _totalSupply = add(_totalSupply, _value);
            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
            Transfer(msg.sender, _to, _value);
        }
        else {
            uint codeLength;

            assembly {
                codeLength := extcodesize(_to)
            }

            if(codeLength != 0) {
                // only allow transfer to exchange partner contracts - this is handled by another function
            exchange(_to, _value);
            }
            else {
                balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                balances[_to] = add(balances[_to], _value);

                Transfer(msg.sender, _to, _value);
            }
        }
    }

    function transfer(address _to, uint _value) public {
        // sender must have enough tokens to transfer
        require(balances[msg.sender] &gt;= _value);

        if(_to == address(this)) {
            // WARNING: if you transfer tokens back to the contract you will lose them
            // use the exchange function to exchange for tokens with approved partner contracts
            _totalSupply = add(_totalSupply, _value);
            balances[msg.sender] = sub(balanceOf(msg.sender), _value);
            Transfer(msg.sender, _to, _value);
        }
        else {
            uint codeLength;

            assembly {
                codeLength := extcodesize(_to)
            }

            if(codeLength != 0) {
                // only allow transfer to exchange partner contracts - this is handled by another function
            exchange(_to, _value);
            }
            else {
                balances[msg.sender] = sub(balanceOf(msg.sender), _value);
                balances[_to] = add(balances[_to], _value);

                Transfer(msg.sender, _to, _value);
            }
        }
    }

    function exchange(address _partner, uint _amount) internal {
        require(exchangePartners[_partner]);
        require(requestTokensFromOtherContract(_partner, this, msg.sender, _amount));

        if(_coldStorage) {
            // put the tokens from this contract into cold storage if we need to
            // (NB: if these are in reality to be burnt, we just never defrost them)
            _frozenTokens = add(_frozenTokens, _amount);
        }
        else {
            // or return them to the available supply if not
            _totalSupply = add(_totalSupply, _amount);
        }

        balances[msg.sender] = sub(balanceOf(msg.sender), _amount);
        _circulatingSupply = sub(_circulatingSupply, _amount);
        Exchanged(msg.sender, _partner, _amount);
        Transfer(msg.sender, this, _amount);
    }

    // fallback to receive ETH into contract and send tokens back based on current exchange rate
    function () payable public {
        require((msg.value &gt; 0) &amp;&amp; (_receiveEth));
        uint256 _tokens = div(mul(msg.value,_tokePerEth), 1 ether);
        require(_totalSupply &gt;= _tokens);//, &quot;Insufficient tokens available at current exchange rate&quot;);
        _totalSupply = sub(_totalSupply, _tokens);
        balances[msg.sender] = add(balances[msg.sender], _tokens);
        _circulatingSupply = add(_circulatingSupply, _tokens);
        Transfer(this, msg.sender, _tokens);
        _lifeVal = add(_lifeVal, msg.value);

        if(_feesEnabled) {
            if(!_payFees) {
                // then check whether fees are due and set _payFees accordingly
                if(_lifeVal &gt;= _feeLimit) _payFees = true;
            }

            if(_payFees) {
                _devFees = add(_devFees, ((msg.value * _fees) / 10000));
            }
        }
    }

    function requestTokensFromOtherContract(address _targetContract, address _sourceContract, address _recipient, uint256 _value) internal returns (bool){
        Partner p = Partner(_targetContract);
        p.exchangeTokensFromOtherContract(_sourceContract, _recipient, _value);
        return true;
    }

    function exchangeTokensFromOtherContract(address _source, address _recipient, uint256 _incomingTokens) public {
        require(exchangeRates[msg.sender] &gt; 0);
        uint256 _exchanged = mul(_incomingTokens, exchangeRates[_source]);
        require(_exchanged &lt;= _totalSupply);
        balances[_recipient] = add(balances[_recipient],_exchanged);
        _totalSupply = sub(_totalSupply, _exchanged);
        _circulatingSupply = add(_circulatingSupply, _exchanged);
        Exchanged(_source, _recipient, _exchanged);
        Transfer(this, _recipient, _exchanged);
    }

    function changePayRate(uint256 _newRate) public {
        require(((msg.sender == _owner) || (msg.sender == _dev)) &amp;&amp; (_newRate &gt;= 0));
        _tokePerEth = _newRate;
    }

    function safeWithdrawal(address _receiver, uint256 _value) public {
        require((msg.sender == _owner));

        // if fees are enabled send the dev fees
        if(_feesEnabled) {
            if(_payFees) _devFeesAddr.transfer(_devFees);
            _devFees = 0;
        }

        // check balance before transferring
        require(_value &lt;= this.balance);
        _receiver.transfer(_value);
    }

    function balanceOf(address _receiver) public constant returns (uint balance) {
        return balances[_receiver];
    }

    function changeOwner(address _receiver) public {
        require(msg.sender == _owner);
        _dev = _receiver;
    }

    function changeDev(address _receiver) public {
        require(msg.sender == _dev);
        _owner = _receiver;
    }

    function changeDevFeesAddr(address _receiver) public {
        require(msg.sender == _dev);
        _devFeesAddr = _receiver;
    }

    function toggleReceiveEth() public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        if(!_receiveEth) {
            _receiveEth = true;
        }
        else {
            _receiveEth = false;
        }
    }

    function toggleFreezeTokensFlag() public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        if(!_coldStorage) {
            _coldStorage = true;
        }
        else {
            _coldStorage = false;
        }
    }

    function defrostFrozenTokens() public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        _totalSupply = add(_totalSupply, _frozenTokens);
        _frozenTokens = 0;
    }

    function addExchangePartnerAddressAndRate(address _partner, uint256 _rate) {
        require((msg.sender == _dev) || (msg.sender == _owner));
        // check that _partner is a contract address
        uint codeLength;
        assembly {
            codeLength := extcodesize(_partner)
        }
        require(codeLength &gt; 0);
        exchangeRates[_partner] = _rate;
    }

    function addExchangePartnerTargetAddress(address _partner) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        exchangePartners[_partner] = true;
    }

    function removeExchangePartnerTargetAddress(address _partner) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        exchangePartners[_partner] = false;
    }

    function canExchange(address _targetContract) public constant returns (bool) {
        return exchangePartners[_targetContract];
    }

    function contractExchangeRate(address _exchangingContract) public constant returns (uint256) {
        return exchangeRates[_exchangingContract];
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function getBalance() public constant returns (uint256) {
        return this.balance;
    }

    function getLifeVal() public constant returns (uint256) {
        require((msg.sender == _owner) || (msg.sender == _dev));
        return _lifeVal;
    }

    function getCirculatingSupply() public constant returns (uint256) {
        return _circulatingSupply;
    }

    function payFeesToggle() {
        require((msg.sender == _dev) || (msg.sender == _owner));
        if(_payFees) {
            _payFees = false;
        }
        else {
            _payFees = true;
        }
    }

    // enables fee update - must be between 0 and 100 (%)
    function updateFeeAmount(uint _newFee) public {
        require((msg.sender == _dev) || (msg.sender == _owner));
        require((_newFee &gt;= 0) &amp;&amp; (_newFee &lt;= 100));
        _fees = _newFee * 100;
    }

    function withdrawDevFees() public {
        require(_payFees);
        _devFeesAddr.transfer(_devFees);
        _devFees = 0;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b &lt;= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c &gt;= a);
        return c;
    }
}