/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity 0.4.18;
/// @title Utility Functions for uint8
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e68d8988818a8f878881a68a898996948f8881c8899481">[email&#160;protected]</a>&gt;,
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1c787d727579705c7073736c6e75727b32736e7b">[email&#160;protected]</a>&gt;.
library MathUint8 {
    function xorReduce(
        uint8[] arr,
        uint    len
        )
        internal
        pure
        returns (uint8 res)
    {
        res = arr[0];
        for (uint i = 1; i &lt; len; i++) {
            res ^= arr[i];
        }
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Utility Functions for byte32
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1b7074757c77727a757c5b7774746b6972757c3574697c">[email&#160;protected]</a>&gt;,
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1571747b7c707955797a7a65677c7b723b7a6772">[email&#160;protected]</a>&gt;.
library MathBytes32 {
    function xorReduce(
        bytes32[]   arr,
        uint        len
        )
        internal
        pure
        returns (bytes32 res)
    {
        res = arr[0];
        for (uint i = 1; i &lt; len; i++) {
            res ^= arr[i];
        }
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
  Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/// @title Ring Hash Registry Contract
/// @dev This contracts help reserve ringhashes for miners.
/// @author Kongliang Zhong - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4d2622232a21242c232a0d2122223d3f24232a63223f2a">[email&#160;protected]</a>&gt;,
/// @author Daniel Wang - &lt;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6e0a0f00070b022e0201011e1c07000940011c09">[email&#160;protected]</a>&gt;.
contract RinghashRegistry {
    using MathBytes32   for bytes32[];
    using MathUint8     for uint8[];
    uint public blocksToLive;
    struct Submission {
        address ringminer;
        uint block;
    }
    mapping (bytes32 =&gt; Submission) submissions;
    ////////////////////////////////////////////////////////////////////////////
    /// Events                                                               ///
    ////////////////////////////////////////////////////////////////////////////
    event RinghashSubmitted(
        address indexed _ringminer,
        bytes32 indexed _ringhash
    );
    ////////////////////////////////////////////////////////////////////////////
    /// Constructor                                                          ///
    ////////////////////////////////////////////////////////////////////////////
    function RinghashRegistry(uint _blocksToLive)
        public
    {
        require(_blocksToLive &gt; 0);
        blocksToLive = _blocksToLive;
    }
    ////////////////////////////////////////////////////////////////////////////
    /// Public Functions                                                     ///
    ////////////////////////////////////////////////////////////////////////////
    function submitRinghash(
        address     ringminer,
        bytes32     ringhash
        )
        public
    {
        require(canSubmit(ringhash, ringminer)); //, &quot;Ringhash submitted&quot;);
        submissions[ringhash] = Submission(ringminer, block.number);
        RinghashSubmitted(ringminer, ringhash);
    }
    function batchSubmitRinghash(
        address[]     ringminerList,
        bytes32[]     ringhashList
        )
        external
    {
        uint size = ringminerList.length;
        require(size &gt; 0);
        require(size == ringhashList.length);
        for (uint i = 0; i &lt; size; i++) {
            submitRinghash(ringminerList[i], ringhashList[i]);
        }
    }
    /// @dev Calculate the hash of a ring.
    function calculateRinghash(
        uint        ringSize,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList
        )
        private
        pure
        returns (bytes32)
    {
        require(
            ringSize == vList.length - 1 &amp;&amp; (
            ringSize == rList.length - 1 &amp;&amp; (
            ringSize == sList.length - 1))
        ); //, &quot;invalid ring data&quot;);
        return keccak256(
            vList.xorReduce(ringSize),
            rList.xorReduce(ringSize),
            sList.xorReduce(ringSize)
        );
    }
     /// return value attributes[2] contains the following values in this order:
     /// canSubmit, isReserved.
    function computeAndGetRinghashInfo(
        uint        ringSize,
        address     ringminer,
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList
        )
        external
        view
        returns (bytes32 ringhash, bool[2] attributes)
    {
        ringhash = calculateRinghash(
            ringSize,
            vList,
            rList,
            sList
        );
        attributes[0] = canSubmit(ringhash, ringminer);
        attributes[1] = isReserved(ringhash, ringminer);
    }
    /// @return true if a ring&#39;s hash can be submitted;
    /// false otherwise.
    function canSubmit(
        bytes32 ringhash,
        address ringminer)
        public
        view
        returns (bool)
    {
        require(ringminer != 0x0);
        var submission = submissions[ringhash];
        address miner = submission.ringminer;
        return (
            miner == 0x0 || (
            submission.block + blocksToLive &lt; block.number) || (
            miner == ringminer)
        );
    }
    /// @return true if a ring&#39;s hash was submitted and still valid;
    /// false otherwise.
    function isReserved(
        bytes32 ringhash,
        address ringminer)
        public
        view
        returns (bool)
    {
        var submission = submissions[ringhash];
        return (
            submission.block + blocksToLive &gt;= block.number &amp;&amp; (
            submission.ringminer == ringminer)
        );
    }
}