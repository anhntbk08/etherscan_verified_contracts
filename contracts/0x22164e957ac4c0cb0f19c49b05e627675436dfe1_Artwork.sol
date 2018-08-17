pragma solidity ^0.4.11;

/* Ethart unindexed Factory Contract:

	Ethart ARCHITECTURE
	-------------------
						_________________________________________
						V										V
	Controller --&gt; Registrar &lt;--&gt; Factory Contract1 --&gt; Artwork Contract1
								  Factory Contract2	    Artwork Contract2
								  		...					...
								  Factory ContractN	    Artwork ContractN

	Controller: The controler contract is the owner of the Registrar contract and can
		- Set a new owner
		- Controll the assets of the Registrar (withdraw ETH, transfer, sell, burn pieces owned by the Registrar)
		- The plan is to replace the controller contract with a DAO in preperation for a possible ICO
	
	Registrar:
		- The Registrar contract atcs as the central registry for all sha256 hashes in the Ethart factory contract network.
		- Approved Factory Contracts can register sha256 hashes using the Registrar interface.
		- 2.5% of the art produced and 2.5% of turnover of the contract network will be transfered to the Registrar.
	
	Factory Contracts:
		- Factory Contracts can spawn Artwork Contracts in line with artists specifications
		- Factory Contracts will only spawn Artwork Contracts who&#39;s sha256 hashes are unique per the Registrar&#39;s sha256 registry
		- Factory Contracts will register every new Artwork Contract with it&#39;s details with the Registrar contract
	
	Artwork Contracts:
		- Artwork Contracts act as minimalist decentralized exchanges for their pieces in line with specified conditions
		- Artwork Contracts will interact with the Registrar to issue buyers of pieces a predetermined amount of Patron tokens based on the transaction value 
		- Artwork Contracts can be interacted with by the Controller via the Registrar using their interfaces to transfer, sell, burn etc pieces
	
	(c) Stefan Pernar 2017 - all rights reserved
	(c) ERC20 functions BokkyPooBah 2017. The MIT Licence.

Artworks created with this factory have the following ABI:

[{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;pieceForSale&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_spender&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_amount&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;approve&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;success&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;ownerCommission&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_proofLink&quot;,&quot;type&quot;:&quot;string&quot;}],&quot;name&quot;:&quot;setProof&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;proofLink&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;string&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;totalSupply&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;totalSupply&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;lowestAskAddress&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_from&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_to&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_amount&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;transferFrom&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;success&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;fillBid&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_amount&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;burn&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;success&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;highestBidPrice&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;highestBidAddress&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;highestBidTime&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_owner&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;balanceOf&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;balance&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_from&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_value&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;burnFrom&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;success&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;lowestAskPrice&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;owner&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;cancelBid&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;newOwner&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;changeOwner&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_to&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_amount&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;transfer&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;success&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;pieceWanted&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;bool&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;SHA256ofArtwork&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;bytes32&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_price&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;offerPieceForSale&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;buyPiece&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:true,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;activationTime&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[{&quot;name&quot;:&quot;_owner&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;name&quot;:&quot;_spender&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;allowance&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;remaining&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;piecesOwned&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;cancelSale&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:false,&quot;inputs&quot;:[],&quot;name&quot;:&quot;placeBid&quot;,&quot;outputs&quot;:[],&quot;payable&quot;:true,&quot;type&quot;:&quot;function&quot;},{&quot;constant&quot;:true,&quot;inputs&quot;:[],&quot;name&quot;:&quot;lowestAskTime&quot;,&quot;outputs&quot;:[{&quot;name&quot;:&quot;&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;function&quot;},{&quot;inputs&quot;:[{&quot;name&quot;:&quot;_SHA256ofArtwork&quot;,&quot;type&quot;:&quot;bytes32&quot;},{&quot;name&quot;:&quot;_editionSize&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_title&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_fileLink&quot;,&quot;type&quot;:&quot;string&quot;},{&quot;name&quot;:&quot;_ownerCommission&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;name&quot;:&quot;_owner&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;payable&quot;:false,&quot;type&quot;:&quot;constructor&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:false,&quot;name&quot;:&quot;price&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;seller&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;newLowestAsk&quot;,&quot;type&quot;:&quot;event&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:false,&quot;name&quot;:&quot;price&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;bidder&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;newHighestBid&quot;,&quot;type&quot;:&quot;event&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:false,&quot;name&quot;:&quot;amount&quot;,&quot;type&quot;:&quot;uint256&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;from&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;to&quot;,&quot;type&quot;:&quot;address&quot;}],&quot;name&quot;:&quot;pieceTransfered&quot;,&quot;type&quot;:&quot;event&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:false,&quot;name&quot;:&quot;from&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;to&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;price&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;pieceSold&quot;,&quot;type&quot;:&quot;event&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:true,&quot;name&quot;:&quot;_from&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:true,&quot;name&quot;:&quot;_to&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;_value&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;Transfer&quot;,&quot;type&quot;:&quot;event&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:true,&quot;name&quot;:&quot;_owner&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:true,&quot;name&quot;:&quot;_spender&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;_value&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;Approval&quot;,&quot;type&quot;:&quot;event&quot;},{&quot;anonymous&quot;:false,&quot;inputs&quot;:[{&quot;indexed&quot;:true,&quot;name&quot;:&quot;_owner&quot;,&quot;type&quot;:&quot;address&quot;},{&quot;indexed&quot;:false,&quot;name&quot;:&quot;_amount&quot;,&quot;type&quot;:&quot;uint256&quot;}],&quot;name&quot;:&quot;Burn&quot;,&quot;type&quot;:&quot;event&quot;}]

*/

contract Interface {

	// Ethart network interface
    function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros);		// Registers a new sha256 hash.
	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered);			// Check if a sha256 hash is registared
	function isFactoryApproved (address _factory) returns (bool _approved);						// Check if an address is a registred factory contract
	function issuePatrons (address _to, uint256 _amount);										// Issues Patron tokens according to conditions specified in factory contracts

	// ERC20 interface
    function totalSupply() constant returns (uint256 totalSupply);
	function balanceOf(address _owner) constant returns (uint256 balance);
 	function transfer(address _to, uint256 _value) returns (bool success);
 	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
	function approve(address _spender, uint256 _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);

	function burn(uint256 _amount) returns (bool success);
	function burnFrom(address _from, uint256 _amount) returns (bool success);
}

contract Artwork {

/* 1. Introduction

This text is a plain English translation of the smart contract&#39;s programming logic and represent its terms of use (terms). This plain English translation is a best effort only and while all reasonable precautions have been taken to ensure that the smart contract will behave in the exact way outlined in these terms, mistakes do happen (see The DAO) which may result in unexpected and unintended contract behaviour which may include the total loss of invested funds (Ether), other tokens sent to it as well as accessibility of the contract itself. Due to the nature of smart contracts, once it is deployed on the blockchain it becomes immutably imbedded in it which means that any bugs and/or exploits discovered after deployment are unfixable. Should the code behave differently than outlined in these terms, the code - by the very nature of smart contracts - takes precedent over the terms. By deploying, interacting or otherwise using the smart contract you acknowledge and accept all associated risks while at the same time waive all rights to hold the creator of the smart contract, the artists who deployed the smart contract, its current owner as well as any other parties responsible for potential damages suffered by or caused by you through your interaction with the smart contract to yourself or others. No backsies.

2. Contract deployment

This smart contract enables its owner to issue limited edition pieces of art (pieces) that are cryptographically embedded in the Ethereum blockchain. Every piece can be owned, offered for sale, sold, bought, transferred and burned. The contract accepts bid from interested buyers and allows for the cancelation of bids as well as the cancelation of pieces offered for sale and filling of bids. In addition the owner of the contract as well as Ethart will earn a commission for every future sales of pieces irrespective of who owns, buys or sells them using the contract.

The contract creation costs approximately 1.7-1.8 Mgas - assuming a gas price of 20 Gwei, contract creation will cost ~0.03-0.034 ETH or about $12 (@$300/ETH) on the Ethereum main net. If contract creation is not urgent and Ethereum&#39;s pending transactions pool is not congested gas prices can be lowered to ~4 Gwei which would reduce the cost of deployment to ~$2-$3 per artwork.

During creation the contract asks for the following parameters:

	- The SHA256 hash of your piece (the cryptographic link of your artwork to the Ethereum blockchain)
	- Edition size (the maximum number of pieces you plan to issue)
	- Title (the title or name of your artwork, if any)
	- The link to your file (if any)
	- Custom text
	- The owner&#39;s commission in basis points (i.e. 1/100th of a percent)

SHA256 hash: A SHA256 hash is a fixed length cryptographic digest of a file. On Mac and Linux it can be calculated by opening a terminal window and typing &quot;openssl sha -sha256&quot; followed by a space and the filename (i.e. &quot;openssl sha -sha256 &lt;FILENAME&gt;&quot;) one wants to calculate the hash for. An online tool that serves the same purpose can be found at http://hash.online-convert.com/sha256-generator. By the nature of the cryptographic math the resulting hash is a) a unique fingerprint of the input file which can be independently verified by whomever has access to the original file, b) different for (almost) every file as long as at least one bit is different and c) almost impossible to reverse, meaning you can calculate a SHA256 hash from a file very easily but you can not generate the file from the SHA256 hash. Embedding the SHA256 hash in the contract at it&#39;s deployment therefore proofs that the limited edition pieces controlled by the smart contract&#39;s logic are linked to a particular file: the artwork.

Edition size: The edition size is currently limited to a minimum of 1 and a maximum of 1,000 pieces.

Title: the title is stored as a public string in the contract

File link: So people can independently verify that a particular file is associated with a particular instance of a smart contract you can here specify the publicly accessible link to the file. Note that providing a link is not mandatory and some artists may decide to only provide the SHA256 hash and reveal the actual file associated with it at a later point in time or never.

Custom text: This field can be whatever you want it to be. One use case could be a set of custom attributes for limited edition collectible playing cards. In this case you would format your game card attributes in a standard manner for later use e.g. Strength, Constitution, Dexterity, Intelligence, Wisdom as &quot;12,8,6,9,3&quot; which a later application can then read and interpreted according to your game&#39;s rules.

Owner&#39;s commission: the account that deploys the smart contract can set a commission for future sales that will be paid out to the current owner of smart contract. The commission is specified in basis points where 1 basis point equals 0.01%. The commission must be greater than 0 and lower than 9750. If the owner wants to receive 5% for all future sales for example the commission will have to be set as 500.

At deployment the owner of the smart contract will be set as the account that deployed it. Please make sure to carefully note down your account details including your address, private key, password, JSON file etc and keep it safe and secret. Remember: whoever has access to this information has access to the contract and all the funds and rights associated with it. If you loose this information it is almost certainly lost forever and your funds and artwork with it. Make at least one backup and keep it in a safe location. After contract deployment it is important for you to carefully note down the contract creation transaction receipt number, contract address and ABI for later reference. You and others will require this information to interact with the contract once it is live.

The contract acts as it&#39;s own decentralised exchange with an on chain order book of the lowest ask and highest bid for a piece and allows for trustless trade of the pieces of art via the Ethereum blockchain.

3. Providing a proof

After deployment and before the first pieces can be bought or sold the owner has to provide a proof. This proof demonstrates that the artwork was in fact deployed by the artist. The proof can be in the form of a link to a blog post, a tweet or press release providing at the very least the artwork&#39;s contract address or contract creation transaction number.

4. Ethart commission

The fee for letting you deploy your artworks will be 2.5% of the edition size as well as 2.5% of future revenues. So you basically pay in art. After you have provided the proof, the contract issues 2.5% of the edition size to Ethart automatically as following:

- 1 piece for every 40 pieces increase in edition size
- a (remainder / 40) chance of an additional piece

Example: Say you create a 100 piece limited edition artwork. The contract will then issue at least 2 pieces to Ethart. In addition there will be a 20 in 40 chance (i.e. 50%) that one additional piece will be issued to Ethart. In other words, if you create a limited edition of 1 piece there is a chance of 2.5% that after you provide the proof this one piece will be transferred to Ethart. To avoid disappointment we therefore recommend a minimum edition size of 2 - then you are guaranteed to keep at least one piece with an additional 5% chance of loosing the other. The way the math works out Ethart will on average retain 2.5% of all pieces.

The pieces transferred to Ethart can not be sold or transferred by Ethart for a minimum of one year (31,556,926 seconds) giving you plenty of time to monopolise the market.

5. Changing the owner

The current owner can transfer ownership of the contract to another account.

6. Transferring pieces

Your artworks is in fact an ERC20 token (https://theethereum.wiki/w/index.php/ERC20_Token_Standard) and supports all ERC20 features. Pieces can be transferred to other addresses (as long as they are not being offered for sale) by their respective owners. Make sure that pieces are only being transferred to accounts that have access to their private keys. Pieces send to exchanges or other accounts that do not have access to their private keys will be lost - most likely forever.

7. Offering a piece for sale

The owner of a piece can offer it for sale. The price for which it is offered (the ask) has to be lower than the current lowest ask. Once a piece is offered for sale by its owner for a lower price than the currently lowest ask it will become the lowest ask and replace the previous lowest ask. The sale price has to be specified in wei (1000000000000000000 wei = 1 ETH). Offering a piece for sale at an ask that is lower or equal to the highest bid will result in an instant sale for the highest bid.

8. Canceling a sale

The owner of a piece offered for sale can cancel the sale 24 hours after having offered the piece for sale. The 24 hour limited is intended to prevent owners to offer a piece at an artificially low price, displacing the currently lowest ask and then immediately canceling the sale.

10. Buying a piece

As long as a piece is being offered for sale, anyone can buy it as long as the buyer sends at least the current lowest ask price with the buy order. Any buy orders that do not send at least the current lowest ask price will be rejects. All the funds send with a buy order will be paid out to the seller of the piece, the contract owner as well as Ethart respectively and in proportion to the commission rules outlined above. There will be no refunds for funds sent in excess of the lowest ask price. Once a piece has been sold the lowest ask will be reset and the next piece offered for sale will become the lowest ask if any. Patrons that buy pieces via the artwork’s smart contract will be issued 2.5 Patron tokens for every Ether spend in the transaction.

11. Placing a bid

Buyers can place bids in wei (1000000000000000000 wei = 1 ETH). Bids have to be higher than the currently highest bid. Placing a bid that is higher than the current lowest ask price will result in the bidder instantly buying the piece offered by the lowest ask seller for the bid amount.

12. Cancelling a bid

Bids can be canceled by the buyer 24 hours after they have been placed. The 24 hour limited is intended to prevent buyers from placing an artificially high bid, displacing the currently highest bid and then immediately canceling the bid.

13. Filling a bid

Bids can be filled by anyone who owns a piece. The contract owner has a 24 hour exclusive first right of refusal to fill a bid.

14. Burning a piece

The owner of a piece can burn it, removing it permanently from the pool of available pieces and thereby reducing the edition size. Artists may choose to do so to increase the value of the remaining pieces or for any other reason.

	(c) Stefan Pernar 2017 - all rights reserved
	(c) ERC20 functions BokkyPooBah 2017. The MIT Licence.

*/

/* Public variables */
	address public owner;						// Contract owner.
	bytes32 public SHA256ofArtwork;				// sha256 hash of the artwork.
	uint256 public editionSize;					// The edition size of the artwork.
	string public title;						// The title of the artwork.
	string public fileLink;						// The link to the file of the artwork.
	string public proofLink;					// Link to the creation proof by the artist -&gt; this has to be done after contract creation
	string public customText;					// Custom text
	uint256 public ownerCommission;				// Percent given to the contract owner for every sale - must be &gt;=0 &amp;&amp; &lt;=975 1000 = 100%.
	
	uint256 public lowestAskPrice;				// The lowest price an owner of a piece is willing to sell it for.
	address public lowestAskAddress;			// The address of the lowest ask.
	uint256 public lowestAskTime;				// The time by which the ask can be withdrawn.
	bool public pieceForSale;					// Is a piece for sale?

	uint256 public highestBidPrice;				// The highest price a buyer is willing to pay for a piece.
	address public highestBidAddress;			// The address of the highest bidder
	uint256 public highestBidTime;				// The time by which the bid can be withdrawn
	uint public activationTime;					// Time this contract has been activated.
	bool public pieceWanted;					// Is a buyer interested in a piece?

	/* Events */
	event newLowestAsk (uint256 price, address seller);							// Informs watchers of the contract when a new lowest ask price has been set. (price, seller)
	event newHighestBid (uint256 price, address bidder);							// Informs watchers of the contract when a new highest bid price has been placed. (price, bidder)
	event pieceTransfered (uint256 amount, address from, address to);				// Informs watchers of the contract when a piece has been transfered. (amount, from, to)
	event pieceSold (address from, address to, uint256 price);					// Informs watchers of the contract when a piece has been sold. (from, to, price)

	event Transfer (address indexed _from, address indexed _to, uint256 _value);
	event Approval (address indexed _owner, address indexed _spender, uint256 _value);
	event Burn (address indexed _owner, uint256 _amount);

	/* Other variables */
	bool public proofSet;							// Has the proof been set yet?
	uint256 ethartAward;					// # of pieces awarded to Ethart.

	mapping (address =&gt; uint256) public piecesOwned;				// Maps the number of pieces owned by an address
 	mapping (address =&gt; mapping (address =&gt; uint256)) allowed;		// Used in burnFrom and transferFrom
    address registrar = 0xaD3e7D2788126250d48598e1DB6A2D3E19B89738;						// set after deployment of Registrar contract

	function Artwork (								// Constructor
		bytes32 _SHA256ofArtwork,
		uint256 _editionSize,
		string _title,
		string _fileLink,
		string _customText,
		uint256 _ownerCommission,
		address _owner
	) {
		if (_ownerCommission &gt; 9750 || _ownerCommission &lt;0) {throw;}
		owner = _owner;                            // Owner is set as the address spawning the contract
		SHA256ofArtwork = _SHA256ofArtwork;
		editionSize = _editionSize;
		title = _title;
		fileLink = _fileLink;
		customText = _customText;
		ownerCommission = _ownerCommission;
		activationTime = now;	
	}

    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }

	modifier ethArtOnlyAfterOneYear()
	{
		require(msg.sender != registrar || now &gt; activationTime + 31536000);
		_;
	}

	modifier ownerFirst()
	{
		require(msg.sender == owner || now &gt; highestBidTime + 86400 || piecesOwned[owner] == 0);
		_;
	}

	modifier notLocked(address _owner, uint256 _amount)
	{
		require(_owner != lowestAskAddress || piecesOwned[_owner] &gt; _amount);
		_;
	}

	// allows the current owner to assign a new owner
	function changeOwner (address newOwner) onlyBy (owner) {
		owner = newOwner;
		}

	function setProof (string _proofLink) onlyBy (owner) {
		if (!proofSet) {
			uint256 remainder;
			proofLink = _proofLink;
			proofSet = true;
			remainder = editionSize % 40;
			ethartAward = (editionSize - remainder) / 40;
			if (remainder &gt; 0 &amp;&amp; now % 39 &lt;= remainder) {ethartAward++;}		// Yes - this is gameable - if it is that important to you: go ahead.
			piecesOwned[registrar] = ethartAward;
			piecesOwned[owner] = editionSize - ethartAward;
			}
		else {throw;}
		}

	function transfer(address _to, uint256 _amount) notLocked(msg.sender, _amount) returns (bool success) {
		if (piecesOwned[msg.sender] &gt;= _amount 
			&amp;&amp; _amount &gt; 0
			&amp;&amp; piecesOwned[_to] + _amount &gt; piecesOwned[_to]
			&amp;&amp; _to != 0x0)																// use burn() instead
			{
			piecesOwned[msg.sender] -= _amount;
			piecesOwned[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
			}
			else { return false;}
 		 }

    function totalSupply() constant returns (uint256 totalSupply) {
		totalSupply = editionSize;
		}

	function balanceOf(address _owner) constant returns (uint256 balance) {
 		return piecesOwned[_owner];
		}

 	function transferFrom(address _from, address _to, uint256 _amount) notLocked(_from, _amount) returns (bool success)
		{
			if (piecesOwned[_from] &gt;= _amount
				&amp;&amp; allowed[_from][msg.sender] &gt;= _amount
				&amp;&amp; _amount &gt; 0
				&amp;&amp; piecesOwned[_to] + _amount &gt; piecesOwned[_to]
				&amp;&amp; _to != 0x0															// use burn() instead
				&amp;&amp; (_from != lowestAskAddress || piecesOwned[_from] &gt; _amount))
					{
					piecesOwned[_from] -= _amount;
					allowed[_from][msg.sender] -= _amount;
					piecesOwned[_to] += _amount;
					Transfer(_from, _to, _amount);
					return true;
					} else {return false;}
		}

	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
		}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
		}

	function burn(uint256 _amount) notLocked(msg.sender, _amount) returns (bool success) {
			if (piecesOwned[msg.sender] &gt;= _amount) {
				piecesOwned[msg.sender] -= _amount;
				editionSize -= _amount;
				Burn(msg.sender, _amount);
				return true;
			}
			else {throw;}
		}

	function burnFrom(address _from, uint256 _value) notLocked(_from, _value) returns (bool success) {
		if (piecesOwned[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value) {
			piecesOwned[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			editionSize -= _value;
			Burn(_from, _value);
			return true;
		}
		else {throw;}
	}

	function buyPiece() payable {
		if (pieceForSale &amp;&amp; msg.value &gt;= lowestAskPrice) {
			uint256 _amountOwner;
			uint256 _amountEthart;
			uint256 _amountSeller;
			_amountOwner = msg.value / 10000 * ownerCommission;
			_amountEthart = msg.value / 40;
			_amountSeller = msg.value - _amountOwner - _amountEthart;
			owner.transfer(_amountOwner);									// Transfer the contract owner&#39;s commission
			lowestAskAddress.transfer(_amountSeller);						// Transfer the buy price - commissions to seller
			registrar.transfer(_amountEthart);								// Transfer Ethart comission to Ethart
			piecesOwned[lowestAskAddress]--;
			piecesOwned[msg.sender]++;
			Interface a = Interface(registrar);
			a.issuePatrons(msg.sender, msg.value / 5 * 2);
			pieceSold (lowestAskAddress, msg.sender, msg.value);
			pieceForSale = false;
			lowestAskPrice = 0;
			lowestAskAddress = 0x0;
		}
		else {throw;}
	}

	// Offer a piece for sale at a fixed price - the price has to be lower than the current lowest price
	function offerPieceForSale (uint256 _price) ethArtOnlyAfterOneYear {
		if (_price &lt; lowestAskPrice || !pieceForSale) {
				if (_price &lt;= highestBidPrice) {fillBid();}
				else {
				pieceForSale = true;
				lowestAskPrice = _price;
				lowestAskAddress = msg.sender;
				lowestAskTime = now;
				newLowestAsk (_price, lowestAskAddress);			// alerts contract watchers about new lowest ask price.
				}
		}
		else {throw;}
	}

	// place a bid for any piece in the edition - bid has to be higher than current highest bid
	function placeBid () payable {
		if (msg.value &gt; highestBidPrice || (pieceForSale &amp;&amp; msg.value &gt;= lowestAskPrice)) {
			if (pieceWanted) {highestBidAddress.transfer (highestBidPrice);}
			if (pieceForSale &amp;&amp; msg.value &gt;= lowestAskPrice) {buyPiece();}
			else {
				pieceWanted = true;
				highestBidPrice = msg.value;
				highestBidAddress = msg.sender;
				highestBidTime = now;
				newHighestBid (msg.value, highestBidAddress);
				}
		}
		else {throw;}
	}

	function fillBid () ownerFirst ethArtOnlyAfterOneYear notLocked(msg.sender, 1) {	// Owner has 24h first right of refusual to fill the bid. Ethart can only fill bids after 1 year.
		if (pieceWanted &amp;&amp; piecesOwned[msg.sender] &gt;= 1) {								// If the current lowest ask address wants to fill a bid it has to cancel it&#39;s sale first and then
			uint256 _amountOwner;														// fill the bid.
			uint256 _amountEthart;
			uint256 _amountSeller;
			uint256 patronReward;
			_amountOwner = highestBidPrice / 10000 * ownerCommission;
			_amountEthart = highestBidPrice / 40;
			_amountSeller = highestBidPrice - _amountOwner - _amountEthart;
			owner.transfer(_amountOwner);									// Transfer the contract&#39;s owner&#39;s commission
			msg.sender.transfer(_amountSeller);								// Transfer the buy price - commissions to seller
			registrar.transfer(_amountEthart);								// Transfer Ethart comission to Ethart
			piecesOwned[highestBidAddress]++;
			Interface a = Interface(registrar);
			patronReward = highestBidPrice  / 5 * 2;
			a.issuePatrons(highestBidAddress, patronReward);				
			piecesOwned[msg.sender]--;
			pieceSold (msg.sender, highestBidAddress, highestBidPrice);
			pieceWanted = false;
			highestBidPrice = 0;
			highestBidAddress = 0x0;
		}
		else {throw;}
	}

	// withdraw a bid - bids can only be withdrawn after 24 hours of being placed
	function cancelBid () onlyBy (highestBidAddress){
		if (pieceWanted &amp;&amp; now &gt; highestBidTime + 86400) {
			pieceWanted = false;
			msg.sender.transfer(highestBidPrice);
			highestBidPrice = 0;
			highestBidAddress = 0x0;
			newHighestBid (0, 0x0);
		}
		else {throw;}
	}

	// cancels sales - sales can only be canceled 24 hours after it has been offered for sale
	function cancelSale () onlyBy (lowestAskAddress){
		if(pieceForSale &amp;&amp; now &gt; lowestAskTime + 86400) {
			pieceForSale = false;
			lowestAskPrice = 0;
			lowestAskAddress = 0x0;
			newLowestAsk (0, 0x0);
		}
		else {throw;}
	}

}