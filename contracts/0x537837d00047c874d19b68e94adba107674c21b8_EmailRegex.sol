pragma solidity ^0.4.11;

contract EmailRegex {
  struct State {
    bool accepts;
    function (byte) constant internal returns (State memory) func;
  }

  string public constant regex = &quot;[a-zA-Z0-9._%+-]<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f3d8b3">[email&#160;protected]</a>[a-zA-Z0-9.-_]+\\.[a-zA-Z]{2,}&quot;;

  function s0(byte c) constant internal returns (State memory) {
    c = c;
    return State(false, s0);
  }

  function s1(byte c) constant internal returns (State memory) {
    if (c == 37 || c == 43 || c == 45 || c == 46 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 65 &amp;&amp; c &lt;= 90 || c == 95 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(false, s2);
    }

    return State(false, s0);
  }

  function s2(byte c) constant internal returns (State memory) {
    if (c == 37 || c == 43 || c == 45 || c == 46 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 65 &amp;&amp; c &lt;= 90 || c == 95 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(false, s3);
    }
    if (c == 64) {
      return State(false, s4);
    }

    return State(false, s0);
  }

  function s3(byte c) constant internal returns (State memory) {
    if (c == 37 || c == 43 || c == 45 || c == 46 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 65 &amp;&amp; c &lt;= 90 || c == 95 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(false, s3);
    }
    if (c == 64) {
      return State(false, s4);
    }

    return State(false, s0);
  }

  function s4(byte c) constant internal returns (State memory) {
    if (c &gt;= 46 &amp;&amp; c &lt;= 47 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 58 &amp;&amp; c &lt;= 64 || c &gt;= 65 &amp;&amp; c &lt;= 90 || c &gt;= 91 &amp;&amp; c &lt;= 95 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(false, s5);
    }

    return State(false, s0);
  }

  function s5(byte c) constant internal returns (State memory) {
    if (c == 46) {
      return State(false, s6);
    }
    if (c == 47 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 58 &amp;&amp; c &lt;= 64 || c &gt;= 65 &amp;&amp; c &lt;= 90 || c &gt;= 91 &amp;&amp; c &lt;= 95 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(false, s7);
    }

    return State(false, s0);
  }

  function s6(byte c) constant internal returns (State memory) {
    if (c == 46) {
      return State(false, s6);
    }
    if (c == 47 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 58 &amp;&amp; c &lt;= 64 || c &gt;= 91 &amp;&amp; c &lt;= 95) {
      return State(false, s7);
    }
    if (c &gt;= 65 &amp;&amp; c &lt;= 90 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(false, s8);
    }

    return State(false, s0);
  }

  function s7(byte c) constant internal returns (State memory) {
    if (c == 46) {
      return State(false, s6);
    }
    if (c == 47 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 58 &amp;&amp; c &lt;= 64 || c &gt;= 65 &amp;&amp; c &lt;= 90 || c &gt;= 91 &amp;&amp; c &lt;= 95 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(false, s7);
    }

    return State(false, s0);
  }

  function s8(byte c) constant internal returns (State memory) {
    if (c == 46) {
      return State(false, s6);
    }
    if (c == 47 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 58 &amp;&amp; c &lt;= 64 || c &gt;= 91 &amp;&amp; c &lt;= 95) {
      return State(false, s7);
    }
    if (c &gt;= 65 &amp;&amp; c &lt;= 90 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(true, s9);
    }

    return State(false, s0);
  }

  function s9(byte c) constant internal returns (State memory) {
    if (c == 46) {
      return State(false, s6);
    }
    if (c == 47 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 58 &amp;&amp; c &lt;= 64 || c &gt;= 91 &amp;&amp; c &lt;= 95) {
      return State(false, s7);
    }
    if (c &gt;= 65 &amp;&amp; c &lt;= 90 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(true, s10);
    }

    return State(false, s0);
  }

  function s10(byte c) constant internal returns (State memory) {
    if (c == 46) {
      return State(false, s6);
    }
    if (c == 47 || c &gt;= 48 &amp;&amp; c &lt;= 57 || c &gt;= 58 &amp;&amp; c &lt;= 64 || c &gt;= 91 &amp;&amp; c &lt;= 95) {
      return State(false, s7);
    }
    if (c &gt;= 65 &amp;&amp; c &lt;= 90 || c &gt;= 97 &amp;&amp; c &lt;= 122) {
      return State(true, s10);
    }

    return State(false, s0);
  }

  function matches(string input) constant returns (bool) {
    var cur = State(false, s1);

    for (uint i = 0; i &lt; bytes(input).length; i++) {
      var c = bytes(input)[i];

      cur = cur.func(c);
    }

    return cur.accepts;
  }
}