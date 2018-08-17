pragma solidity ^0.4.11;


//import &quot;../zeppelin-solidity/contracts/ownership/Ownable.sol&quot;;

contract paperCash {
	mapping (bytes32 =&gt; uint) grants;
	mapping (bytes32 =&gt; bool) claimed;

	function createGrant(bytes32 _hashedKey)
		payable
	{
		require(grants[_hashedKey] == 0);
		require(claimed[_hashedKey] == false);

		require(msg.value &gt; 0);
		grants[_hashedKey] = msg.value;

		LogGrantCreated(_hashedKey, msg.value);
	}

	function claimGrant(bytes32 _key) 
	{
		bytes32 hashedKey = sha3(_key);

		require(!claimed[hashedKey]);
		claimed[hashedKey] = true;

		uint amount = grants[hashedKey];
		require(amount &gt; 0);

		require(msg.sender.send(amount));

		LogGrantClaimed(hashedKey, amount);
	}

	event LogGrantCreated(bytes32 hashedKey, uint amount);
	event LogGrantClaimed(bytes32 hashedKey, uint amount);
}