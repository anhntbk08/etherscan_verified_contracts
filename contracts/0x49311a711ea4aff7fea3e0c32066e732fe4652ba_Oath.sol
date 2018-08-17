contract Oath {
	mapping (address =&gt; bytes) public sig;

	event LogSignature(address indexed from, bytes version);

	function Oath() {
		if(msg.value &gt; 0) { throw; }
	}

	function sign(bytes version) public {
		if(sig[msg.sender].length != 0 ) { throw; }
		if(msg.value &gt; 0) { throw; }

		sig[msg.sender] = version;
		LogSignature(msg.sender, version);
	}

	function () { throw; }
}