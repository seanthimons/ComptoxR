"""Offline source/provenance/closure and current-parent collision checks."""
import hashlib, json, pathlib, yaml, os
root = pathlib.Path('.')
parent = pathlib.Path(os.environ['SEARCH_SERVICES_PARENT']).resolve() if 'SEARCH_SERVICES_PARENT' in os.environ else None
canonical = json.loads((root / 'schema/chemi-services-prod.json').read_text())
derivative = json.loads((root / 'schema/chemi-services-reviewed-preflight.json').read_text())
expected = json.loads(json.dumps(canonical))
for diff in json.loads((root / 'dev/search-services/upload-semantic-diff.json').read_text()):
    keys = [x.replace('~1', '/').replace('~0', '~') for x in diff['path'].split('/')[1:]]
    op = expected
    for key in keys:
        op = op[key]
    for key, value in diff['remove'].items():
        assert op.pop(key) == value
    for key, value in diff['add'].items():
        assert key not in op
        op[key] = value
assert expected == derivative

def refs(node, document):
    if isinstance(node, list):
        for value in node:
            refs(value, document)
    elif isinstance(node, dict):
        if '$ref' in node:
            ref = node['$ref']
            assert ref.startswith('#/')
            target = document
            for key in ref[2:].split('/'):
                target = target[key.replace('~1', '/').replace('~0', '~')]
        for value in node.values():
            refs(value, document)

hashes = {}
for file in ['schema/chemi-services-prod.json', 'schema/chemi-search-prod.json']:
    data = (root / file).read_bytes()
    if parent is not None:
        assert data == (parent / file).read_bytes()
    assert hashlib.sha256(data).hexdigest() == json.loads((root / 'dev/search-services/source-proof.json').read_text())['canonical_sha256'][file]
    refs(json.loads(data), json.loads(data))
    hashes[file] = hashlib.sha256(data).hexdigest()
refs(derivative, derivative)
rows = json.loads((root / 'dev/search-services/scope.json').read_text())
for row in rows:
    method, path = row['key'].split(' ', 1)
    assert json.loads((root / row['schema']).read_text())['paths'][path][method.lower()] == row['operation']
    if parent is not None:
        assert not (parent / 'R' / (row['name'] + '.R')).exists()
        for file in (parent / 'apis').glob('*.yml'):
            config = yaml.safe_load(file.read_text())
            assert not any(op.get('name') == row['name'] or op.get('file') == 'R/' + row['name'] + '.R'
                           for op in (config.get('operations') or {}).values())
owners = json.loads((root / 'dev/search-services/legacy-before/owners.json').read_text())
for name in ['chemi_services_convert', 'chemi_services_collated_report']:
    frozen = root / 'dev/search-services/legacy-before' / (name + '.R')
    normalized = frozen.read_text().replace('\r\n', '\n').replace('\r', '\n').rstrip('\n')
    assert hashlib.sha256(normalized.encode()).hexdigest() == owners['R/' + name + '.R']['hash']
    if parent is not None:
        assert frozen.read_bytes() == (parent / 'R' / (name + '.R')).read_bytes()
print('Canonical hashes, exact derivative diff, full reference closure and frozen legacy owner hashes passed.')
