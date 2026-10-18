"""Guard against timed-out native operation replies satisfying a later request.
Actual ANE/runtime acceptance still needs native integration.
"""
from pathlib import Path
p=Path(__file__).resolve().parents[2]/'src/PGSNativeTransport.as'
s=p.read_text()
checks={
'read has request token': 'context.call("read", slot, pendingId)' in s,
'write has request token': 'context.call("write", slot, snapshot, pendingId)' in s,
'authorize has request token': 'context.call("authorize", pendingId)' in s,
'events must match pending token': 'data.requestId !== pendingId' in s,
'timeout identifies its original token': 'onRequestTimeout(requestId:uint)' in s and 'pendingId != requestId' in s,
'completed request invalidates token': 'pendingId = 0;' in s,
}
for n,v in checks.items():print(('PASS' if v else 'FAIL'),n)
assert all(checks.values())
