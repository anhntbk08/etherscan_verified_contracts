// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the &quot;License&quot;).
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

// Code taken from https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol
// Audit, refactoring and improvements by github.com/Eenae

// @authors:
// Gav Wood &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7f183f1a0b171b1a09511c1012">[email&#160;protected]</a>&gt;
// inheritable &quot;property&quot; contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.

pragma solidity ^0.4.15;


/// note: during any ownership changes all pending operations (waiting for more signatures) are cancelled
// TODO acceptOwnership
contract multiowned {

	// TYPES

    // struct for the status of a pending operation.
    struct MultiOwnedOperationPendingState {
        // count of confirmations needed
        uint yetNeeded;

        // bitmap of confirmations where owner #ownerIndex&#39;s decision corresponds to 2**ownerIndex bit
        uint ownersDone;

        // position of this operation key in m_multiOwnedPendingIndex
        uint index;
    }

	// EVENTS

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event FinalConfirmation(address owner, bytes32 operation);

    // some others are in the case of an owner changing.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);

    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

	// MODIFIERS

    // simple single-sig function modifier.
    modifier onlyowner {
        require(isOwner(msg.sender));
        _;
    }
    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation)) {
            _;
        }
        // Even if required number of confirmations has&#39;t been collected yet,
        // we can&#39;t throw here - because changes to the state have to be preserved.
        // But, confirmAndCheck itself will throw in case sender is not an owner.
    }

    modifier validNumOwners(uint _numOwners) {
        require(_numOwners &gt; 0 &amp;&amp; _numOwners &lt;= c_maxOwners);
        _;
    }

    modifier multiOwnedValidRequirement(uint _required, uint _numOwners) {
        require(_required &gt; 0 &amp;&amp; _required &lt;= _numOwners);
        _;
    }

    modifier ownerExists(address _address) {
        require(isOwner(_address));
        _;
    }

    modifier ownerDoesNotExist(address _address) {
        require(!isOwner(_address));
        _;
    }

    modifier multiOwnedOperationIsActive(bytes32 _operation) {
        require(isOperationActive(_operation));
        _;
    }

	// METHODS

    // constructor is given number of sigs required to do protected &quot;onlymanyowners&quot; transactions
    // as well as the selection of addresses capable of confirming them (msg.sender is not added to the owners!).
    address[] _owners;
    function multiowned() public
    {
        uint _required = 2;

        _owners.push(address(0xdA8f27f49bd46B7a16FEfbC504e79F16b7113200));
_owners.push(address(0x338bf5A8Bb77c3fF6E112cb1287B87f92D154b36));
_owners.push(address(0x5A68063ea1980D80Cb89eB89161a2240Df592133));

        require(_owners.length &gt; 0 &amp;&amp; _owners.length &lt;= c_maxOwners);
        require(_required &gt; 0 &amp;&amp; _required &lt;= _owners.length);

        assert(c_maxOwners &lt;= 255);

        m_numOwners = _owners.length;
        m_multiOwnedRequired = _required;

        for (uint i = 0; i &lt; _owners.length; ++i)
        {
            address owner = _owners[i];
            // invalid and duplicate addresses are not allowed
            require(0 != owner &amp;&amp; !isOwner(owner) /* not isOwner yet! */);

            uint currentOwnerIndex = checkOwnerIndex(i + 1 /* first slot is unused */);
            m_owners[currentOwnerIndex] = owner;
            m_ownerIndex[owner] = currentOwnerIndex;
        }

        assertOwnersAreConsistent();
    }

    /// @notice replaces an owner `_from` with another `_to`.
    /// @param _from address of owner to replace
    /// @param _to address of new owner
    // All pending operations will be canceled!
    function changeOwner(address _from, address _to)
        external
        ownerExists(_from)
        ownerDoesNotExist(_to)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
        m_owners[ownerIndex] = _to;
        m_ownerIndex[_from] = 0;
        m_ownerIndex[_to] = ownerIndex;

        assertOwnersAreConsistent();
        OwnerChanged(_from, _to);
    }

    /// @notice adds an owner
    /// @param _owner address of new owner
    // All pending operations will be canceled!
    function addOwner(address _owner)
        external
        ownerDoesNotExist(_owner)
        validNumOwners(m_numOwners + 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        m_numOwners++;
        m_owners[m_numOwners] = _owner;
        m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

        assertOwnersAreConsistent();
        OwnerAdded(_owner);
    }

    /// @notice removes an owner
    /// @param _owner address of owner to remove
    // All pending operations will be canceled!
    function removeOwner(address _owner)
        external
        ownerExists(_owner)
        validNumOwners(m_numOwners - 1)
        multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
        m_owners[ownerIndex] = 0;
        m_ownerIndex[_owner] = 0;
        //make sure m_numOwners is equal to the number of owners and always points to the last owner
        reorganizeOwners();

        assertOwnersAreConsistent();
        OwnerRemoved(_owner);
    }

    /// @notice changes the required number of owner signatures
    /// @param _newRequired new number of signatures required
    // All pending operations will be canceled!
    function changeRequirement(uint _newRequired)
        external
        multiOwnedValidRequirement(_newRequired, m_numOwners)
        onlymanyowners(keccak256(msg.data))
    {
        m_multiOwnedRequired = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

    /// @notice Gets an owner by 0-indexed position
    /// @param ownerIndex 0-indexed owner position
    function getOwner(uint ownerIndex) public constant returns (address) {
        return m_owners[ownerIndex + 1];
    }

    /// @notice Gets owners
    /// @return memory array of owners
    function getOwners() public constant returns (address[]) {
        address[] memory result = new address[](m_numOwners);
        for (uint i = 0; i &lt; m_numOwners; i++)
            result[i] = getOwner(i);

        return result;
    }

    /// @notice checks if provided address is an owner address
    /// @param _addr address to check
    /// @return true if it&#39;s an owner
    function isOwner(address _addr) public constant returns (bool) {
        return m_ownerIndex[_addr] &gt; 0;
    }

    /// @notice Tests ownership of the current caller.
    /// @return true if it&#39;s an owner
    // It&#39;s advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
    // addOwner/changeOwner and to isOwner.
    function amIOwner() external constant onlyowner returns (bool) {
        return true;
    }

    /// @notice Revokes a prior confirmation of the given operation
    /// @param _operation operation value, typically keccak256(msg.data)
    function revoke(bytes32 _operation)
        external
        multiOwnedOperationIsActive(_operation)
        onlyowner
    {
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        var pending = m_multiOwnedPending[_operation];
        require(pending.ownersDone &amp; ownerIndexBit &gt; 0);

        assertOperationIsConsistent(_operation);

        pending.yetNeeded++;
        pending.ownersDone -= ownerIndexBit;

        assertOperationIsConsistent(_operation);
        Revoke(msg.sender, _operation);
    }

    /// @notice Checks if owner confirmed given operation
    /// @param _operation operation value, typically keccak256(msg.data)
    /// @param _owner an owner address
    function hasConfirmed(bytes32 _operation, address _owner)
        external
        constant
        multiOwnedOperationIsActive(_operation)
        ownerExists(_owner)
        returns (bool)
    {
        return !(m_multiOwnedPending[_operation].ownersDone &amp; makeOwnerBitmapBit(_owner) == 0);
    }

    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation)
        private
        onlyowner
        returns (bool)
    {
        if (512 == m_multiOwnedPendingIndex.length)
            // In case m_multiOwnedPendingIndex grows too much we have to shrink it: otherwise at some point
            // we won&#39;t be able to do it because of block gas limit.
            // Yes, pending confirmations will be lost. Dont see any security or stability implications.
            // TODO use more graceful approach like compact or removal of clearPending completely
            clearPending();

        var pending = m_multiOwnedPending[_operation];

        // if we&#39;re not yet working on this operation, switch over and reset the confirmation status.
        if (! isOperationActive(_operation)) {
            // reset count of confirmations needed.
            pending.yetNeeded = m_multiOwnedRequired;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_multiOwnedPendingIndex.length++;
            m_multiOwnedPendingIndex[pending.index] = _operation;
            assertOperationIsConsistent(_operation);
        }

        // determine the bit to set for this owner.
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        // make sure we (the message sender) haven&#39;t confirmed this operation previously.
        if (pending.ownersDone &amp; ownerIndexBit == 0) {
            // ok - check if count is enough to go ahead.
            assert(pending.yetNeeded &gt; 0);
            if (pending.yetNeeded == 1) {
                // enough confirmations: reset and run interior.
                delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
                delete m_multiOwnedPending[_operation];
                FinalConfirmation(msg.sender, _operation);
                return true;
            }
            else
            {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
                assertOperationIsConsistent(_operation);
                Confirmation(msg.sender, _operation);
            }
        }
    }

    // Reclaims free slots between valid owners in m_owners.
    // TODO given that its called after each removal, it could be simplified.
    function reorganizeOwners() private {
        uint free = 1;
        while (free &lt; m_numOwners)
        {
            // iterating to the first free slot from the beginning
            while (free &lt; m_numOwners &amp;&amp; m_owners[free] != 0) free++;

            // iterating to the first occupied slot from the end
            while (m_numOwners &gt; 1 &amp;&amp; m_owners[m_numOwners] == 0) m_numOwners--;

            // swap, if possible, so free slot is located at the end after the swap
            if (free &lt; m_numOwners &amp;&amp; m_owners[m_numOwners] != 0 &amp;&amp; m_owners[free] == 0)
            {
                // owners between swapped slots should&#39;t be renumbered - that saves a lot of gas
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() private onlyowner {
        uint length = m_multiOwnedPendingIndex.length;
        // TODO block gas limit
        for (uint i = 0; i &lt; length; ++i) {
            if (m_multiOwnedPendingIndex[i] != 0)
                delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
        }
        delete m_multiOwnedPendingIndex;
    }

    function checkOwnerIndex(uint ownerIndex) private pure returns (uint) {
        assert(0 != ownerIndex &amp;&amp; ownerIndex &lt;= c_maxOwners);
        return ownerIndex;
    }

    function makeOwnerBitmapBit(address owner) private constant returns (uint) {
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
        return 2 ** ownerIndex;
    }

    function isOperationActive(bytes32 _operation) private constant returns (bool) {
        return 0 != m_multiOwnedPending[_operation].yetNeeded;
    }


    function assertOwnersAreConsistent() private constant {
        assert(m_numOwners &gt; 0);
        assert(m_numOwners &lt;= c_maxOwners);
        assert(m_owners[0] == 0);
        assert(0 != m_multiOwnedRequired &amp;&amp; m_multiOwnedRequired &lt;= m_numOwners);
    }

    function assertOperationIsConsistent(bytes32 _operation) private constant {
        var pending = m_multiOwnedPending[_operation];
        assert(0 != pending.yetNeeded);
        assert(m_multiOwnedPendingIndex[pending.index] == _operation);
        assert(pending.yetNeeded &lt;= m_multiOwnedRequired);
    }


   	// FIELDS

    uint constant c_maxOwners = 250;

    // the number of owners that must confirm the same operation before it is run.
    uint public m_multiOwnedRequired;


    // pointer used to find a free slot in m_owners
    uint public m_numOwners;

    // list of owners (addresses),
    // slot 0 is unused so there are no owner which index is 0.
    // TODO could we save space at the end of the array for the common case of &lt;10 owners? and should we?
    address[256] internal m_owners;

    // index on the list of owners to allow reverse lookup: owner address =&gt; index in m_owners
    mapping(address =&gt; uint) internal m_ownerIndex;


    // the ongoing operations.
    mapping(bytes32 =&gt; MultiOwnedOperationPendingState) internal m_multiOwnedPending;
    bytes32[] internal m_multiOwnedPendingIndex;
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic demonstration of multi-owned entity.
 */
contract SimpleMultiSigWallet is multiowned {

    event Deposit(address indexed sender, uint value);
    event EtherSent(address indexed to, uint value);
    event TokensSent(address token, address indexed to, uint value);

    function SimpleMultiSigWallet()
        multiowned()
        public
        payable
    {
        
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
        public
    {
        if (msg.value &gt; 0)
            Deposit(msg.sender, msg.value);
    }

    /// @notice Send `value` of ether to address `to`
    /// @param to where to send ether
    /// @param value amount of wei to send
    function sendEther(address to, uint value)
        external
        onlymanyowners(keccak256(msg.data))
    {
        require(address(0) != to);
        require(value &gt; 0 &amp;&amp; this.balance &gt;= value);
        to.transfer(value);
        EtherSent(to, value);
    }
    
    function sendTokens(address token, address to, uint value)
        external
        onlymanyowners(keccak256(msg.data))
        returns (bool)
    {
        require(address(0) != to);
        
        if (ERC20Basic(token).transfer(to, value)) {
            TokensSent(token, to, value);
            return true;
        }
        
        return false;
    }
    
    function tokenBalance(address token) external view returns (uint256) {
        return ERC20Basic(token).balanceOf(this);
    }
}