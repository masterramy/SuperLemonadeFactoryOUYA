#!/usr/bin/env python3
"""Cloud coordination regression contracts for same-session callbacks and post-upload drift.
This is source/logic evidence only, not ActionScript execution or Google network acceptance.
"""
from pathlib import Path
s=(Path(__file__).resolve().parents[2]/'src/CloudSyncCoordinator.as').read_text()
assert 'operationId' in s, 'Every sync must own a unique generation'
assert 'generation != operationId' in s, 'Late async callbacks from older syncs must be discarded'
assert 'CloudProgressCodec.merge(snapshot, latest)' in s, 'A successful upload must recheck post-upload local progress'
assert 'local_progress_pending' in s, 'Unuploaded recent progress must not be called synced'
assert 'MAX_LOCAL_RECHECKS' in s, 'Local changes during network writes cannot cause infinite reuploads'

# Contract simulation: a local achievement earned after a write begins cannot
# be reported "synced" until it has either been uploaded or explicitly deferred.
def uploaded_is_complete(snapshot, local_after_write):
    return all(x <= y for x,y in zip(local_after_write, snapshot))
assert not uploaded_is_complete([0,1,0],[1,1,0]), 'New achievement needs reupload'
assert uploaded_is_complete([1,1,0],[1,1,0])
print('PASS cloud post-upload drift + stale-generation source contracts')
