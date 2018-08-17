pragma solidity ^0.4.11;

/*
  Allows buyers to securely/confidently buy recent ICO tokens that are
  still non-transferrable, on an IOU basis. Like HitBTC, but with protection,
  control, and guarantee of either the purchased tokens or ETH refunded.

  The Buyer&#39;s ETH will be locked into the contract until the purchased
  IOU/tokens arrive here and are ready for the buyer to invoke withdraw(),
  OR until cut-off time defined below is exceeded and as a result ETH
  refunds/withdrawals become enabled.

  In other words, the seller must fulfill the IOU token purchases any time
  before the cut-off time defined below, otherwise the buyer gains the
  ability to withdraw their ETH.

  The buyer&#39;s ETH will ONLY be released to the seller AFTER the adequate
  amount of tokens have been deposited for ALL purchases.

  Estimated Time of Distribution: 3-5 weeks from ICO according to TenX
  Cut-off Time: ~ August 9, 2017

  Greetz: blast, cintix
  <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="187e77777a796a7a7162796a6a7d587f75797174367b7775">[email&#160;protected]</a> (Please report any findings or suggestions for a 1 ETH bounty!)

  Thank you
*/

contract ERC20 {
  function transfer(address _to, uint _value);
  function balanceOf(address _owner) constant returns (uint balance);
}

contract IOU {
  // Store the amount of IOUs purchased by a buyer
  mapping (address =&gt; uint256) public iou_purchased;

  // Store the amount of ETH sent in by a buyer
  mapping (address =&gt; uint256) public eth_sent;

  // Total IOUs available to sell
  uint256 public total_iou_available = 20000000000000000000;

  // Total IOUs purchased by all buyers
  uint256 public total_iou_purchased;

  // Total IOU withdrawn by all buyers (keep track to protect buyers)
  uint256 public total_iou_withdrawn;

  // IOU per ETH (price)
  uint256 public price_per_eth = 8600;

  //  PAY token contract address (IOU offering)
  ERC20 public token = ERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);

  // The seller&#39;s address (to receive ETH upon distribution, and for authing safeties)
  address seller = 0x007937cd579875A1b9e4E485a49Ee8147BC03a37;

  // Halt further purchase ability just in case
  bool public halt_purchases;

  /*
    Safety to withdraw unbought tokens back to seller. Ensures the amount
    that buyers still need to withdraw remains available
  */
  function withdrawTokens() {
    if(msg.sender != seller) throw;
    token.transfer(seller, token.balanceOf(address(this)) - (total_iou_purchased - total_iou_withdrawn));
  }

  /*
    Safety to prevent anymore purchases/sales from occurring in the event of
    unforeseen issue. Buyer withdrawals still remain enabled.
  */
  function haltPurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = true;
  }

  function resumePurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = false;
  }

  /*
    Update available IOU to purchase
  */
  function updateAvailability(uint256 _iou_amount) {
    if(msg.sender != seller) throw;
    if(_iou_amount &lt; total_iou_purchased) throw;

    total_iou_available = _iou_amount;
  }

  /*
    Update IOU price
  */
  function updatePrice(uint256 _price) {
    if(msg.sender != seller) throw;
    price_per_eth = _price;
  }

  /*
    Release buyer&#39;s ETH to seller ONLY if amount of contract&#39;s tokens balance
    is &gt;= to the amount that still needs to be withdrawn. Protects buyer.

    The seller must call this function manually after depositing the adequate
    amount of tokens for all buyers to collect, as defined by total_iou_purchased

    This effectively ends the sale, but withdrawals remain open indefinitely
  */
  function paySeller() {
    if(msg.sender != seller) throw;

    // not enough tokens in balance to release ETH, protect buyer and abort
    if(token.balanceOf(address(this)) &lt; (total_iou_purchased - total_iou_withdrawn)) throw;

    // Halt further purchases to prevent accidental over-selling
    halt_purchases = true;

    // Release buyer&#39;s ETH to the seller
    seller.transfer(this.balance);
  }

  function withdraw() payable {
    /*
      Main mechanism to ensure a buyer&#39;s purchase/ETH/IOU is safe.

      Refund the buyer&#39;s ETH if we&#39;re beyond the cut-off date of our distribution
      promise AND if the contract doesn&#39;t have an adequate amount of tokens
      to distribute to the buyer. Time-sensitive buyer/ETH protection is only
      applicable if the contract doesn&#39;t have adequate tokens for the buyer.

      The &quot;adequacy&quot; check prevents the seller and/or third party attacker
      from locking down buyers&#39; ETH by sending in an arbitrary amount of tokens.

      If for whatever reason the tokens remain locked for an unexpected period
      beyond the time defined by block.number, patient buyers may still wait until
      the contract is filled with their purchased IOUs/tokens. Once the tokens
      are here, they can initiate a withdraw() to retrieve their tokens. Attempting
      to withdraw any sooner (after the block has been mined, but tokens not arrived)
      will result in a refund of buyer&#39;s ETH.
    */
    if(block.number &gt; 4199999 &amp;&amp; iou_purchased[msg.sender] &gt; token.balanceOf(address(this))) {
      // We didn&#39;t fulfill our promise to have adequate tokens withdrawable at xx time
      // Refund the buyer&#39;s ETH automatically instead
      uint256 eth_to_refund = eth_sent[msg.sender];

      // If the user doesn&#39;t have any ETH or tokens to withdraw, get out ASAP
      if(eth_to_refund == 0 || iou_purchased[msg.sender] == 0) throw;

      // Adjust total purchased so others can buy, and so numbers align with total_iou_withdrawn
      total_iou_purchased -= iou_purchased[msg.sender];

      // Clear record of buyer&#39;s ETH and IOU balance before refunding
      eth_sent[msg.sender] = 0;
      iou_purchased[msg.sender] = 0;

      msg.sender.transfer(eth_to_refund);
      return;
    }

    /*
      Check if there is an adequate amount of tokens in the contract yet
      and allow the buyer to withdraw tokens and release ETH to the seller if so
    */
    if(token.balanceOf(address(this)) == 0 || iou_purchased[msg.sender] &gt; token.balanceOf(address(this))) throw;

    uint256 iou_to_withdraw = iou_purchased[msg.sender];

    // If the user doesn&#39;t have any IOUs to withdraw/release, get out ASAP
    if(iou_to_withdraw == 0) throw;

    // Clear record of buyer&#39;s IOU and ETH balance before transferring out
    iou_purchased[msg.sender] = 0;
    eth_sent[msg.sender] = 0;

    total_iou_withdrawn += iou_to_withdraw;

    // Distribute tokens to the buyer
    token.transfer(msg.sender, iou_to_withdraw);
  }

  function purchase() payable {
    if(halt_purchases) throw;

    // Determine amount of tokens user wants to/can buy
    uint256 iou_to_purchase = price_per_eth * msg.value; // price is 160 per ETH

    // Check if we have enough IOUs left to sell
    if((total_iou_purchased + iou_to_purchase) &gt; total_iou_available) throw;

    // Update the amount of IOUs purchased by user. Also keep track of the total ETH they sent in
    iou_purchased[msg.sender] += iou_to_purchase;
    eth_sent[msg.sender] += msg.value;

    // Update the total amount of IOUs purchased by all buyers
    total_iou_purchased += iou_to_purchase;
  }

  // Fallback function/entry point
  function () payable {
    if(msg.value == 0) {
      withdraw();
    }
    else {
      purchase();
    }
  }
}