"""AS3 transport compile-contract guard: lost native callback cannot wedge sync forever."""
from pathlib import Path
s=(Path(__file__).resolve().parents[2]/'src/PGSNativeTransport.as').read_text()
checks={
'uses ActionScript timer API': 'import flash.utils.setTimeout;' in s and 'import flash.utils.clearTimeout;' in s,
'bounds native request': 'MAX_REQUEST_MILLIS' in s and 'setTimeout(function():void' in s and 'onRequestTimeout(requestId);' in s,
'read timeout armed': 'pendingType = "read";' in s and 'armTimeout();' in s,
'authorize, read and write timeouts armed': 'pendingType = "write";' in s and s.count('armTimeout();') == 3,
'completion clears timeout': 'clearRequestTimeout();' in s,
'late callback ignored without pending': 'if (pending == null) return;' in s,
}
for title,ok in checks.items():print(('PASS' if ok else 'FAIL'),title)
assert all(checks.values())
