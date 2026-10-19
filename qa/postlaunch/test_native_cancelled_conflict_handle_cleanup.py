"""Canceled Play Games conflicts release both snapshot views rather than leaking."""
from pathlib import Path
source=(Path(__file__).resolve().parents[2]/"native/pgs-ane/src/main/java/com/ramybaheeg/slfport/pgs/PGSExtension.java").read_text()
cleanup=source[source.index("private void discardStaleOpen("):source.index("private void handleOpenResult(")]
assert "result.getConflict()" in cleanup
assert "getSnapshot()" in cleanup and "getConflictingSnapshot()" in cleanup
assert "client.discardAndClose(server)" in cleanup
assert "client.discardAndClose(device)" in cleanup
assert "device != server" in cleanup
handler=source[source.index("private void handleOpenResult("):source.index("@Override public Map<String,FREFunction>")]
assert 'if(retries>=MAX_NATIVE_CONFLICT_RETRIES){\n                discardStaleOpen(result, operationClient);' in handler
print("PASS canceled/unresolvable snapshot conflict cleanup")
