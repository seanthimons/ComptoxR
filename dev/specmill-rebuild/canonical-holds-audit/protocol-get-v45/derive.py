"""Reproduce the separately reviewed GET subset; run from the ComptoxR root."""
import copy
import hashlib
import json
from pathlib import Path

work = Path.home() / '.cache/comptoxr-specmill-finish/protocol-get-candidate'
canonical_path = Path('schema/chemi-stdizer-prod.json')
canonical = json.loads(canonical_path.read_text())
assert hashlib.sha256(canonical_path.read_bytes()).hexdigest() == '178680219fccf31ecd6778532e69deff196e3767e3f8b6b3558d1cc3256f12ec'
post = json.loads(Path('schema/chemi-stdizer-reviewed-protocol-search.json').read_text())
route = '/api/stdizer/protocols/{id}'
op = copy.deepcopy(canonical['paths'][route]['get'])
assert op['parameters'][-1]['name'] == 'pageable'
op['parameters'] = op['parameters'][:-1] + copy.deepcopy(post['paths'][route]['post']['parameters'][1:])
refs = set()
def visit(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key == '$ref':
                assert child.startswith('#/components/schemas/')
                name = child.rsplit('/', 1)[1]
                if name not in refs:
                    refs.add(name)
                    visit(canonical['components']['schemas'][name])
            else:
                visit(child)
    elif isinstance(value, list):
        for child in value:
            visit(child)
visit(op)
schema = copy.deepcopy(post)
schema['paths'] = {route: {'get': op}}
schema['components']['schemas'] = {key: canonical['components']['schemas'][key] for key in sorted(refs)}
encoded = (json.dumps(schema, indent=2) + '\n').encode()
assert hashlib.sha256(encoded).hexdigest() == '36ff68551f9dc9ef891fe47e691473f1818f0f1114125a315abdec4e7ffd2e5d'
assert encoded == (work / 'schema/chemi-stdizer-reviewed-protocol-get.json').read_bytes()
assert op['responses'] == canonical['paths'][route]['get']['responses']
assert op['parameters'][:6] == canonical['paths'][route]['get']['parameters'][:6]
assert schema['servers'] == [{'url': 'https://hcd.rtpnc.epa.gov'}]
print('PASS: exact GET derivation, preserved booleans/responses and canonical component closure.')
