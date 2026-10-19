#!/usr/bin/env python3
"""Leaving Options must cancel native operations before releasing UI state."""
from pathlib import Path
r=Path(__file__).resolve().parents[2]
s=(r/'src/PCOptionsState.as').read_text()
t=(r/'src/PGSNativeTransport.as').read_text()
a=s.index('override public function destroy():void')
segment=s[a:s.index('super.destroy();',a)]
assert 'cloudProvider.dispose();' in segment
assert 'cloudStatusText = null;' in segment
assert segment.index('cloudStatusText = null;') < segment.index('cloudProvider.dispose();')
assert 'cloudSyncContract = null;' in segment
assert 'context.call("cancel", pendingId)' in t
print('PASS Options exit cancels in-flight PGS before removing UI')
