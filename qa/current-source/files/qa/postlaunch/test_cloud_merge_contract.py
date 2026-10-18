#!/usr/bin/env python3
"""External Python contract simulation. It does NOT execute ActionScript; only
checks the intended merge behavior against the exact 24 fields/labels parsed
from the original game Registry and validates the source checks are present.
"""
import json, re, random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
CODEC=(ROOT/'src/CloudProgressCodec.as').read_text()
REG=(ROOT/'src/Registry.as').read_text()
FIELDS=re.findall(r'save\.data\.([A-Za-z]+)\s*=\s*normaliseProgressArray\(save\.data\.\w+,\s*"([^"]+)"', REG)
assert len(FIELDS)==24 and len(set(k for k,_ in FIELDS))==24
assert 'validFieldSet(local)' in CODEC and 'validFieldSet(remote)' in CODEC
assert 'FIELDS.indexOf(key) < 0' in CODEC and 'local.schema !== SCHEMA' in CODEC
assert 'l[i] is String' in CODEC and 'r[i] is String' in CODEC, 'Actual ActionScript must reject numeric/bool slot coercion'
assert 'envelopeKeys != 2' in CODEC and 'data.arrays is Array' in CODEC

def snapshot(seed=0):
    rng=random.Random(seed)
    return {'schema':1,'arrays':{name:[label]+[rng.choice(['0','1']) for _ in range(12)] for name,label in FIELDS}}

def merge(left,right):
    if (set(left) != {'schema','arrays'} or set(right) != {'schema','arrays'}):return None
    if (type(left['schema']) is not int or type(right['schema']) is not int or left['schema'] != 1 or right['schema'] != 1):return None
    if not isinstance(left['arrays'],dict) or not isinstance(right['arrays'],dict):return None
    keys={n for n,_ in FIELDS}
    if set(left.get('arrays',{})) != keys or set(right.get('arrays',{})) != keys:return None
    result={'schema':1,'arrays':{}}
    for name,label in FIELDS:
        a,b=left['arrays'][name],right['arrays'][name]
        if not (isinstance(a,list) and isinstance(b,list) and len(a)==len(b)==13 and a[0]==b[0]==label):return None
        if any(type(x) is not str or x not in ('0','1') for x in a[1:]+b[1:]):return None
        result['arrays'][name]=[label]+['1' if x=='1' or y=='1' else '0' for x,y in zip(a[1:],b[1:])]
    return result

checks=0
for n in range(60):
    a,b=snapshot(n),snapshot(n+1000)
    out=merge(a,b)
    assert out and merge(b,a)==out
    assert merge(out,a)==out and merge(out,b)==out
    for field,_ in FIELDS:
        assert all(x=='1' or y=='0' for x,y in zip(out['arrays'][field][1:],a['arrays'][field][1:]))
    checks+=1
s=snapshot(2);t=snapshot(4)
for mutator in (
    lambda q: q.update(schema='1'),
    lambda q: q['arrays'].pop(FIELDS[3][0]),
    lambda q: q['arrays'].update(unknownField=['x']+['0']*12),
    lambda q: q['arrays'][FIELDS[3][0]].__setitem__(0,FIELDS[4][1]),
    lambda q: q['arrays'][FIELDS[3][0]].__setitem__(5,'true'),
    lambda q: q['arrays'][FIELDS[3][0]].append('0'),
    lambda q: q['arrays'][FIELDS[3][0]].__setitem__(4,1),
    lambda q: q['arrays'][FIELDS[3][0]].__setitem__(4,0),
    lambda q: q['arrays'][FIELDS[3][0]].__setitem__(4,True),
    lambda q: q.update(unexpected='surprise'),
    lambda q: q.update(arrays=[]),
    lambda q: q.update(schema=True),
):
    broken=json.loads(json.dumps(t));mutator(broken)
    assert merge(s,broken) is None
    checks+=1
print(f'PASS {checks} independent cloud merge contract simulations (60 randomized pairs, 12 corrupt snapshots); runtime not implied')
