pragma solidity ^0.4.10;

contract addGenesisPairs {
    
address[] newParents;
address[] newChildren;

function addGenesisPairs()    {
    // Set elixor contract address
    elixor elixorContract=elixor(0x898bF39cd67658bd63577fB00A2A3571dAecbC53);
    
    newParents=[
        0x1e7A4C807477B84FE84517DD7B5882176EDDD2b5,
0x5a20D58B3836992F6be0edFD318BCAfd69EA678D,
0x3f0fbE5815F9A70DEF46822dcF70E877CFc4f19B,
0x6AaE47c35Fd4D5Dc0Ca75ee99FC10e9ebFB8eDBB,
0x0A6C8d771429b3bAAf78f7b1B5Fc9E4e04D36dAf,
0xb29Ef2F507336d2b41764DBDa770a22FDb819a30,
0xb83ad7CfF43aB1277Cdb5b86bd6DcEfa65e71923,
0x7b8F09d2c9B87CAf01fB84aa5e8Bb21F55933cDb,
0x5d8e50165972B9eBD8a0029475c553e2c73397d4,
0x5Ff3481B1B2e67D082Ab76E04467dcC64108Ccd6,
0x3a9244dd69C1203FC6D5F26cE3Ed168a2ac7B5e8,
0xb2e363b8050e99Bba747ddC338af473Db3EB1F7B,
0xe388442776C854AffF1c486F7EF9db851730C8bD,
0xC5F2C4df8d34a1533030d41f75CD3a2D0c779B12,
0x3aa43B43D23744192e2683dC1FfAA448c23D4709,
0xC6c48e94305F5D7fceCE65b34Bbc9E921c0c1c6F,
0x8d1DA0F11673224e1A494C6019e2047dE6b0D988,
0x3b0c480daBe06DF7B398a2E9319b5f59A32a291A,
0x26b5cAa349c172105691adEec8F37a6a152FE883,
0xfCFB8665C10D441818887739696e3bb164888EF2,
0x4016E5aA7FeA6d08deF64c6a8Cc0B246073E97a3,
0xC2E4AA3f7eF336B9fe1237484c62D95046C77BEc,
0x5F25D207583c718d334DA52192368fF77dba0D12
    ];
    
    
    
    newChildren=[0xCe79eCE3dDBAe131a7405D2099b2EEdcF9E59d6A,
0xA3e88FA08238510369F76d48D1D8FBf9354b4A7C,
0x9b9b5555663f91f3087320FC80bd8e2eaFa615b8,
0x33605985E83eE62ed790cd81e9AADC7C7d6702da,
0xc0B177935027C4DcA66Aa97C72f8174f9C19bE9a,
0xdA984F07F97013b650f96A351323E217ea924A30,
0x908001753ACe62db8FC20E9e5B2845947fb24CcE,
0xbf20c37EFA33074D17e4FE33855b631D93233adf,
0x8286C95D56029eaef10dE004CA8B248B072b9DBF,
0x457C9F8E8aB263869D16a539aF5dC431399EFb24,
0xB65B033eC11683178aB74e811acBcF80c2adA54C,
0xa2DFA3a1348bA76CEA95eAd781eE56e20C82AAb1,
0xfff3a92258829400dC4416b9f71b63fc61466044,
0xffca506375F110152359C8de5A0e2F3590fa1cE3,
0xE1860CfA07f6Fc1D7C1b40139A89fB05E3009b0d,
0xbEc8A2d1a97f3274B77472c7A02150A3F7C082E4,
0x8d1DA0F11673224e1A494C6019e2047dE6b0D988,
0x8519E8D53699855A404Abf94407FF5C626EEb6fb,
0xA2D1cC72a7C9a3e68dEF67Cd6FF438c8e92cd370,
0x05c7EaFC51B4189076669F4188a46f93794E02c5,
0x8Ffd89fAD110F62dC8fF511e428aeAc00B11D2Cd,
0xc88001d5FF49c0d9763825124035b4Bb4591fB83,
0x59991e0dA5b7bA0E46d620876bde064213A2d823
    ];
    
    elixorContract.importGenesisPairs(newParents,newChildren);
 
}

}

contract elixor {
    function importGenesisPairs(address[] newParents,address[] newChildren) public;
}