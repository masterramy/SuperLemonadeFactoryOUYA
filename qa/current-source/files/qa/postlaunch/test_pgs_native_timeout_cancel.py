#!/usr/bin/env python3
"""Timed-out AS3 Play Games requests must cancel native work and quarantine sync.
Source contract only; hardware/OAuth testing remains separate.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[3]
a=(root/'src/PGSNativeTransport.as').read_text()
n=(root/'native/pgs-ane/src/main/java/com/ramybaheeg/slfport/pgs/PGSExtension.java').read_text()
assert 'functions.put("cancel"' in n
start=a.index('private function onRequestTimeout(')
end=a.index('private function fail(',start)
body=a[start:end]
assert 'context.call("cancel", requestId)' in body
assert 'extensionSupported = false;' in body and 'ready = false;' in body
assert body.index('context.call("cancel", requestId)') < body.index('fail("error")')
print('PASS timeout cancels native request and disables quarantined cloud provider')
