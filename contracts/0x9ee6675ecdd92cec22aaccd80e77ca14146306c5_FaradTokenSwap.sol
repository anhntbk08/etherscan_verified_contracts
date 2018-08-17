/**
 * Copyright (C) Virtue Fintech FZ-LLC, Dubai
 * All rights reserved.
 * Author: <span class="__cf_email__" data-cfemail="d0bdb8b990a6b9a2a4a5b5feb6b9beb1beb3b5">[email&#160;protected]</span> 
 *
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the &quot;&quot;Software&quot;&quot;), to 
 * deal in the Software without restriction, including without limitation the 
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
 * sell copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions: 
 *  The above copyright notice and this permission notice shall be included in 
 *  all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
 * THE SOFTWARE.
 *
 */
pragma solidity ^0.4.11;

/**
 * Guards is a handful of modifiers to be used throughout this project
 */
contract Guarded {

    modifier isValidAmount(uint256 _amount) { 
        require(_amount &gt; 0); 
        _; 
    }

    // ensure address not null, and not this contract address
    modifier isValidAddress(address _address) {
        require(_address != 0x0 &amp;&amp; _address != address(this));
        _;
    }

}

contract Ownable {
    address public owner;

    /** 
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner. 
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to. 
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b &lt;= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a);
        return c;
    }
}


contract FaradTokenSwap is Guarded, Ownable {

    using SafeMath for uint256;

    mapping(address =&gt; uint256) contributions;          // contributions from public
    uint256 contribCount = 0;

    string public version = &#39;0.1.2&#39;;

    uint256 public startBlock = 4280263;                // 16th September 2017, 00:00:00 - 1505520000
    uint256 public endBlock = 4334263;                  // 30th September 2017, 23:59:59 - 1506815999

    uint256 public totalEtherCap = 1184834 ether;       // Total raised for ICO, at USD 211/ether
    uint256 public weiRaised = 0;                       // wei raised in this ICO
    uint256 public minContrib = 0.05 ether;             // min contribution accepted

    address public wallet = 0xDe4A2bcFeB9986022b8F1C87bc21C5a8687B038B;

    event Contribution(address indexed _contributor, uint256 _amount);

    function FaradTokenSwap() {
    }

    // function to start the Token Sale
    /// start the token sale at `_starBlock`
    function setStartBlock(uint256 _startBlock) onlyOwner public {
        startBlock = _startBlock;
    }

    // function to stop the Token Swap 
    /// stop the token swap at `_endBlock`
    function setEndBlock(uint256 _endBlock) onlyOwner public {
        endBlock = _endBlock;
    }

    // this function is to add the previous token sale balance.
    /// set the accumulated balance of `_weiRaised`
    function setWeiRaised(uint256 _weiRaised) onlyOwner public {
        weiRaised = weiRaised.add(_weiRaised);
    }

    // set the wallet address
    /// set the wallet at `_wallet`
    function setWallet(address _wallet) onlyOwner public {
        wallet = _wallet;
    }

    /// set the minimum contribution to `_minContrib`
    function setMinContribution(uint256 _minContrib) onlyOwner public {
        minContrib = _minContrib;
    }

    // @return true if token swap event has ended
    function hasEnded() public constant returns (bool) {
        return block.number &gt;= endBlock;
    }

    // @return true if the token swap contract is active.
    function isActive() public constant returns (bool) {
        return block.number &gt;= startBlock &amp;&amp; block.number &lt;= endBlock;
    }

    function () payable {
        processContributions(msg.sender, msg.value);
    }

    /**
     * Okay, we changed the process flow a bit where the actual FRD to ETH
     * mapping shall be calculated, and pushed to the contract once the
     * crowdsale is over.
     *
     * Then, the user can pull the tokens to their wallet.
     *
     */
    function processContributions(address _contributor, uint256 _weiAmount) payable {
        require(validPurchase());

        uint256 updatedWeiRaised = weiRaised.add(_weiAmount);

        // update state
        weiRaised = updatedWeiRaised;

        // notify event for this contribution
        contributions[_contributor] = contributions[_contributor].add(_weiAmount);
        contribCount += 1;
        Contribution(_contributor, _weiAmount);

        // forware the funds
        forwardFunds();
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        uint256 current = block.number;

        bool withinPeriod = current &gt;= startBlock &amp;&amp; current &lt;= endBlock;
        bool minPurchase = msg.value &gt;= minContrib;

        // add total wei raised
        uint256 totalWeiRaised = weiRaised.add(msg.value);
        bool withinCap = totalWeiRaised &lt;= totalEtherCap;

        // check all 3 conditions met
        return withinPeriod &amp;&amp; minPurchase &amp;&amp; withinCap;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

}