"""Avoid use of nullable PGS context client in asynchronous read/write callbacks."""
from pathlib import Path
s=(Path(__file__).resolve().parents[2]/"native/pgs-ane/src/main/java/com/ramybaheeg/slfport/pgs/PGSExtension.java").read_text()
for name,part in (("read",s[s.index('functions.put("read"'):s.index('functions.put("write"')]),("write",s[s.index('functions.put("write"'):s.index("return functions;",s.index('functions.put("write"'))])):
    async_body=part[part.index("operationClient.open("):]
    assert "snapshots.discardAndClose(" not in async_body,name
    assert "snapshots.commitAndClose(" not in async_body,name
    assert "operationClient.discardAndClose(" in async_body,name
assert "operationClient.commitAndClose(" in s
assert "if (!current(id)) {\n                                    operationClient.discardAndClose(snapshot);\n                                    return;" in s
print("PASS snapshot cleanup never dereferences disposed context client")
