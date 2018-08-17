pragma solidity ^0.4.15;

contract tickets {
    
    mapping(uint256 =&gt; uint256) public ticketPrices;
    mapping(address =&gt; uint256[]) public ticketsOwners;
    mapping(uint256 =&gt; address) public ticketsOwned;
    mapping(address =&gt; uint256) public noOfTicketsOwned;
    mapping(address =&gt; bool) public banned;
    uint256 noOfSeats;
    
    mapping(address =&gt; uint256[]) public reservations;
    mapping(address =&gt; uint256) public noOfreservations;
    mapping(address =&gt; uint256) public timeOfreservations;
    mapping(address =&gt; uint256) public priceOfreservations;
    mapping(uint256 =&gt; address) public addressesReserving;
    uint256 public lowestAddressReserving=0;
    uint256 public highestAddressReserving=0;
    
    mapping(uint256 =&gt; uint256[]) public ticketTransfers;
    mapping(uint256 =&gt; uint256) public ticketTransfersPerAmount;
    uint256 public ticketTransfersAmount = 0;
    mapping(address =&gt; uint256[]) public ticketTransferers;
    mapping(address =&gt; uint256) public ticketTransferersAmount;
    mapping(address =&gt; uint256[]) public ticketTransferees;
    mapping(address =&gt; uint256) public ticketTransfereesAmount;
    
    mapping(address =&gt; bytes32) public hashes;
    
    string public name;
    
    uint256 public secondsToHold = 60 * 5 ;
    
    address public owner;
    
    function tickets(uint256[] ticks, uint256 nOfSeats, string n) {
        for(uint256 i=0;i&lt;nOfSeats;i++) {
            ticketPrices[i] = ticks[i];
        }
        noOfSeats = nOfSeats;
        name = n;
        owner = msg.sender;
    }
    
    function reserveSeats(uint256[] seats, uint256 nOfSeats) {
        if(noOfreservations[msg.sender] != 0 &amp;&amp; !banned[msg.sender]) {
            revert();
        }
        resetReservationsInternal();
        uint256 price = 0;
        for(uint256 i=0;i&lt;nOfSeats;i++) {
            if(ticketsOwned[seats[i]] != 0x0) {
                revert();
            }
            reservations[msg.sender].push(seats[i]);
            price += ticketPrices[seats[i]];
            ticketsOwned[seats[i]] = msg.sender;
        }
        noOfreservations[msg.sender] = nOfSeats;
        timeOfreservations[msg.sender] = now;
        priceOfreservations[msg.sender] = price;
        noOfTicketsOwned[msg.sender]++;
        highestAddressReserving++;
        Reserved(msg.sender, seats);
    }
    
    function resetReservations(address requester, bool resetOwn) {
        if(noOfreservations[requester] == 0) {
            throw;
        }
        for(uint256 i=0;i&lt;noOfreservations[requester] &amp;&amp; resetOwn;i++) {
            ticketsOwned[reservations[requester][i]] = 0x0;
            noOfTicketsOwned[msg.sender]--;
        }
        reservations[requester] = new uint256[](0);
        noOfreservations[requester] = 0;
        timeOfreservations[requester] = 0;
        priceOfreservations[requester] = 0;
    }
    
    function resetReservationsInternal() private {
        bool pastTheLowest = false;
        bool stop = false;
        for(uint256 i=lowestAddressReserving;i&lt;highestAddressReserving &amp;&amp; !stop;i++) {
            if(timeOfreservations[addressesReserving[i]] != 0) {
                pastTheLowest = true;
                if(now - timeOfreservations[addressesReserving[i]] &gt; secondsToHold) {
                    resetReservations(addressesReserving[i], true);
                } else {
                    stop = true;
                }
            }
            if(timeOfreservations[addressesReserving[i]] == 0 &amp;&amp; !pastTheLowest) {
                lowestAddressReserving = i;
            }
            
        }
    }
    
    function revokeTickets(address revokee, bool payback) payable {
        if(msg.sender == owner) {
            banned[revokee] = true;
            uint256 price = 0;
            for(uint256 i=0;i&lt;noOfTicketsOwned[revokee];i++) {
                ticketsOwned[ticketsOwners[revokee][i]] = 0x0;
                price+=ticketPrices[ticketsOwners[revokee][i]];
            }
            ticketsOwners[revokee] = new uint256[](0);
            noOfTicketsOwned[revokee] = 0;
            if(payback) {
                revokee.send(price);
            }
            Banned(revokee, payback);
        }
    }
    
    function InvokeTransfer(address transferee, uint256[] ticks, uint256 amount) {
        if(amount&gt;0 &amp;&amp; getTransfer(msg.sender,transferee) != 100000000000000000) {
            for(uint256 i=0;i&lt;amount;i++) {
                ticketTransfers[ticketTransfersAmount].push(ticks[i]);
            }
            ticketTransferers[msg.sender][ticketTransferersAmount[msg.sender]++] = ticketTransfersAmount;
            ticketTransferees[transferee][ticketTransfereesAmount[transferee]++] = ticketTransfersAmount;
            ticketTransfersPerAmount[ticketTransfersAmount] = amount;
            TransferStarted(msg.sender, transferee, ticks, ticketTransfersAmount++);
        } else {
            revert();
        }
    }
    
    function removeTransfer(uint256 transferID) {
        bool transferer = false;
        for(uint256 i=0;i&lt;ticketTransferersAmount[msg.sender] &amp;&amp; !transferer;i++) {
            if(ticketTransferers[msg.sender][i] == transferID) {
                transferer = true;
            }
        }
        if(transferer) {
            ticketTransfers[transferID] = new uint256[](0);
        } else {
            revert();
        }
    }
    
    function finishTransfer(uint256 transferID) payable {
        bool transferee = false;
        for(uint256 j=0;j&lt;ticketTransfereesAmount[msg.sender] &amp;&amp; !transferee;j++) {
            if(ticketTransferees[msg.sender][j] == transferID) {
                transferee = true;
            }
        }
        if(!transferee) {
            revert();
        }
        uint256 price = 0;
        for(uint256 i=0;i&lt;ticketTransfersPerAmount[transferID];i++) {
            price += ticketPrices[ticketTransfers[transferID][i]];
        }
        if(msg.value == price) {
            for(i=0;i&lt;ticketTransfersPerAmount[transferID];i++) {
                ticketsOwned[ticketTransfers[transferID][i]] = msg.sender;
            }
            Transferred(transferID);
        } else {
            revert();
        }
    }
    
    function getTransfer(address transferer, address transferee) returns (uint256) {
        for(uint256 i=0;i&lt;ticketTransferersAmount[transferer];i++) {
            for(uint256 j=0;j&lt;ticketTransfereesAmount[transferee];j++) {
                if(ticketTransferers[transferer][i] == ticketTransferees[transferee][j]) {
                    return ticketTransferees[transferee][j];
                }
            }
        }
        return 100000000000000000;
    }
    
    function setHash(bytes32 hash) {
        hashes[msg.sender] = hash;
    }
    
    function checkHash(address a, string password) constant returns (bool) {
        return hashes[a]!=&quot;&quot; &amp;&amp; hashes[a] == sha3(password);
    }
    
    function() payable {
        if(msg.value == priceOfreservations[msg.sender] &amp;&amp; !banned[msg.sender]) {
            for(uint256 i=0;i&lt;noOfreservations[msg.sender];i++) {
                ticketsOwners[msg.sender].push(reservations[msg.sender][i]);
            }
            resetReservations(msg.sender, false);
            owner.send(msg.value);
            Confirmed(msg.sender);
        } else {
            revert();
        }
    }
    
    event Reserved(address indexed _to, uint256[] _tickets);
    event Confirmed(address indexed _to);
    event TransferStarted(address indexed _from, address indexed _to, uint256[] _tickets, uint256 _transferID);
    event Transferred(uint256 _transferID);
    event Banned(address indexed _banned, bool payback);
    
}