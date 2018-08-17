pragma solidity ^0.4.18;

contract iBird {

    string public symbol = &quot;iBird&quot;;
    string public name = &quot;iBird Token&quot;;
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 0;
  uint256 _FreeiBird = 50000;
    uint256 _ML1 = 2;
    uint256 _ML2 = 3;
  uint256 _ML3 = 4;
    uint256 _LimitML1 = 3e15;
    uint256 _LimitML2 = 6e15;
  uint256 _LimitML3 = 9e15;
  uint256 _MaxDistribPublicSupply = 20000000000;
    uint256 _OwnerDistribSupply = 0;
    uint256 _CurrentDistribPublicSupply = 0;  
    uint256 _ExtraTokensPerETHSended = 5000000000;
    
  address _DistribFundsReceiverAddress = 0;
    address _remainingTokensReceiverAddress = 0;
    address owner = 0;
  
  
    bool setupDone = false;
    bool IsDistribRunning = false;
    bool DistribStarted = false;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _owner, uint256 _value);

    mapping(address =&gt; uint256) balances;
    mapping(address =&gt; mapping(address =&gt; uint256)) allowed;
    mapping(address =&gt; bool) public Claimed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Makindo() public {
        owner = msg.sender;
    }

    function() public payable {
        if (IsDistribRunning) {
            uint256 _amount;
            if (((_CurrentDistribPublicSupply + _amount) &gt; _MaxDistribPublicSupply) &amp;&amp; _MaxDistribPublicSupply &gt; 0) revert();
            if (!_DistribFundsReceiverAddress.send(msg.value)) revert();
            if (Claimed[msg.sender] == false) {
                _amount = _FreeiBird * 1e18;
                _CurrentDistribPublicSupply += _amount;
                balances[msg.sender] += _amount;
                _totalSupply += _amount;
                Transfer(this, msg.sender, _amount);
                Claimed[msg.sender] = true;
            }

           

            if (msg.value &gt;= 9e15) {
            _amount = msg.value * _ExtraTokensPerETHSended * 4;
            } else {
                if (msg.value &gt;= 6e15) {
                    _amount = msg.value * _ExtraTokensPerETHSended * 3;
                } else {
                    if (msg.value &gt;= 3e15) {
                        _amount = msg.value * _ExtraTokensPerETHSended * 2;
                    } else {

                        _amount = msg.value * _ExtraTokensPerETHSended;

                    }

                }
            }
       
       _CurrentDistribPublicSupply += _amount;
                balances[msg.sender] += _amount;
                _totalSupply += _amount;
                Transfer(this, msg.sender, _amount);
        



        } else {
            revert();
        }
    }

    function SetupiBird(string tokenName, string tokenSymbol, uint256 ExtraTokensPerETHSended, uint256 MaxDistribPublicSupply, uint256 OwnerDistribSupply, address remainingTokensReceiverAddress, address DistribFundsReceiverAddress, uint256 FreeiBird) public {
        if (msg.sender == owner &amp;&amp; !setupDone) {
            symbol = tokenSymbol;
            name = tokenName;
            _FreeiBird = FreeiBird;
            _ExtraTokensPerETHSended = ExtraTokensPerETHSended;
            _MaxDistribPublicSupply = MaxDistribPublicSupply * 1e18;
            if (OwnerDistribSupply &gt; 0) {
                _OwnerDistribSupply = OwnerDistribSupply * 1e18;
                _totalSupply = _OwnerDistribSupply;
                balances[owner] = _totalSupply;
                _CurrentDistribPublicSupply += _totalSupply;
                Transfer(this, owner, _totalSupply);
            }
            _DistribFundsReceiverAddress = DistribFundsReceiverAddress;
            if (_DistribFundsReceiverAddress == 0) _DistribFundsReceiverAddress = owner;
            _remainingTokensReceiverAddress = remainingTokensReceiverAddress;

            setupDone = true;
        }
    }

    function SetupML(uint256 ML1inX, uint256 ML2inX, uint256 LimitML1inWei, uint256 LimitML2inWei) onlyOwner public {
        _ML1 = ML1inX;
        _ML2 = ML2inX;
        _LimitML1 = LimitML1inWei;
        _LimitML2 = LimitML2inWei;
        
    }

    function SetExtra(uint256 ExtraTokensPerETHSended) onlyOwner public {
        _ExtraTokensPerETHSended = ExtraTokensPerETHSended;
    }

    function SetFreeMKI(uint256 FreeiBird) onlyOwner public {
        _FreeiBird = FreeiBird;
    }

    function StartDistrib() public returns(bool success) {
        if (msg.sender == owner &amp;&amp; !DistribStarted &amp;&amp; setupDone) {
            DistribStarted = true;
            IsDistribRunning = true;
        } else {
            revert();
        }
        return true;
    }

    function StopDistrib() public returns(bool success) {
        if (msg.sender == owner &amp;&amp; IsDistribRunning) {
            if (_remainingTokensReceiverAddress != 0 &amp;&amp; _MaxDistribPublicSupply &gt; 0) {
                uint256 _remainingAmount = _MaxDistribPublicSupply - _CurrentDistribPublicSupply;
                if (_remainingAmount &gt; 0) {
                    balances[_remainingTokensReceiverAddress] += _remainingAmount;
                    _totalSupply += _remainingAmount;
                    Transfer(this, _remainingTokensReceiverAddress, _remainingAmount);
                }
            }
            DistribStarted = false;
            IsDistribRunning = false;
        } else {
            revert();
        }
        return true;
    }

    function distribution(address[] addresses, uint256 _amount) onlyOwner public {

        uint256 _remainingAmount = _MaxDistribPublicSupply - _CurrentDistribPublicSupply;
        require(addresses.length &lt;= 255);
        require(_amount &lt;= _remainingAmount);
        _amount = _amount * 1e18;

        for (uint i = 0; i &lt; addresses.length; i++) {
            require(_amount &lt;= _remainingAmount);
            _CurrentDistribPublicSupply += _amount;
            balances[addresses[i]] += _amount;
            _totalSupply += _amount;
            Transfer(this, addresses[i], _amount);

        }

        if (_CurrentDistribPublicSupply &gt;= _MaxDistribPublicSupply) {
            DistribStarted = false;
            IsDistribRunning = false;
        }
    }

    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner public {

        uint256 _remainingAmount = _MaxDistribPublicSupply - _CurrentDistribPublicSupply;
        uint256 _amount;

        require(addresses.length &lt;= 255);
        require(addresses.length == amounts.length);

        for (uint8 i = 0; i &lt; addresses.length; i++) {
            _amount = amounts[i] * 1e18;
            require(_amount &lt;= _remainingAmount);
            _CurrentDistribPublicSupply += _amount;
            balances[addresses[i]] += _amount;
            _totalSupply += _amount;
            Transfer(this, addresses[i], _amount);


            if (_CurrentDistribPublicSupply &gt;= _MaxDistribPublicSupply) {
                DistribStarted = false;
                IsDistribRunning = false;
            }
        }
    }

    function BurnTokens(uint256 amount) public returns(bool success) {
        uint256 _amount = amount * 1e18;
        if (balances[msg.sender] &gt;= _amount) {
            balances[msg.sender] -= _amount;
            _totalSupply -= _amount;
            Burn(msg.sender, _amount);
            Transfer(msg.sender, 0, _amount);
        } else {
            revert();
        }
        return true;
    }

    function totalSupply() public constant returns(uint256 totalSupplyValue) {
        return _totalSupply;
    }

    function MaxDistribPublicSupply_() public constant returns(uint256 MaxDistribPublicSupply) {
        return _MaxDistribPublicSupply;
    }

    function OwnerDistribSupply_() public constant returns(uint256 OwnerDistribSupply) {
        return _OwnerDistribSupply;
    }

    function CurrentDistribPublicSupply_() public constant returns(uint256 CurrentDistribPublicSupply) {
        return _CurrentDistribPublicSupply;
    }

    function RemainingTokensReceiverAddress() public constant returns(address remainingTokensReceiverAddress) {
        return _remainingTokensReceiverAddress;
    }

    function DistribFundsReceiverAddress() public constant returns(address DistribfundsReceiver) {
        return _DistribFundsReceiverAddress;
    }

    function Owner() public constant returns(address ownerAddress) {
        return owner;
    }

    function SetupDone() public constant returns(bool setupDoneFlag) {
        return setupDone;
    }

    function IsDistribRunningFalg_() public constant returns(bool IsDistribRunningFalg) {
        return IsDistribRunning;
    }

    function IsDistribStarted() public constant returns(bool IsDistribStartedFlag) {
        return DistribStarted;
    }

    function balanceOf(address _owner) public constant returns(uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns(bool success) {
        if (balances[msg.sender] &gt;= _amount &amp;&amp;
            _amount &gt; 0 &amp;&amp;
            balances[_to] + _amount &gt; balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns(bool success) {
        if (balances[_from] &gt;= _amount &amp;&amp;
            allowed[_from][msg.sender] &gt;= _amount &amp;&amp;
            _amount &gt; 0 &amp;&amp;
            balances[_to] + _amount &gt; balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) public returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
}