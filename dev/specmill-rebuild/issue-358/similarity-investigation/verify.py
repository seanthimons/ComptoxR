"""Check saved observations without contacting any service."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent


def result(environment, name):
    return json.loads((root / f'{environment}-{name}.json').read_text())


for environment in ['development', 'production']:
    for name in ['frontend-full', 'alias-scoring']:
        r = result(environment, name)
        assert r['status'] == 200
        assert len(r['response']) == 1
        row = r['response'][0]
        assert row['chemical']['sid'] == 'DTXSID9020112'
        assert row['similarity']['sim'] == 0.138
assert result('development', 'self-only')['response'] == []
assert result('development', 'other-only')['response'][0]['chemical']['sid'] == 'DTXSID9020112'
assert result('development', 'reverse-reference')['response'][0]['chemical']['sid'] == 'DTXSID7020182'
for name, field in [('alias-minimal', 'fingerprintName'), ('fingerprint-only', 'scoreName'),
                    ('declared-full', '_chemicals')]:
    r = result('development', name)
    assert r['status'] == 400
    assert field in r['response']['detail']
assert result('development', 'minimal-chemicals')['status'] == 200
assert result('development', 'smiles-only')['response'][0]['similarity']['sim'] == 0.138
print('Saved positive results, reference exclusion and input failures verified.')
