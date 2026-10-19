from pathlib import Path
r=Path(__file__).resolve().parents[2]
i=(r/'src/ICloudSaveTransport.as').read_text()
c=(r/'src/CloudSyncCoordinator.as').read_text()
t=(r/'src/PGSNativeTransport.as').read_text()
checks={
 'interface differentiates extension support and sign-in': 'function get supported():Boolean;' in i and 'function authorize(completed:Function):void;' in i,
 'no sign-in before consent': 'if (busy || !consent' in c and 'transport.authorize(' in c and c.index('if (busy || !consent') < c.index('transport.authorize('),
 'sync waits for sign-in status before reading': 'transport.authorize(function(status:String):void' in c and 'self.readFresh(generation);' in c,
 'extension supports opt-in sign-in operation': 'context.call("authorize", pendingId)' in t and 'pendingType = "authorize"' in t,
 'provider can report installed but unauthenticated': 'context.call("signedIn")' in t,
 'network remains disabled if not signed in': 'return ready && context != null;' in t,
 'no production extension declaration': 'com.ramybaheeg.slfport.pgs.savedgames' not in (r/'application.xml').read_text(),
}
for name,yes in checks.items():print(('PASS' if yes else 'FAIL'),name)
assert all(checks.values())
