"""Derive the reviewed GET-only contract without modifying the canonical source."""
import copy
import hashlib
import json
from pathlib import Path

canonical = Path('schema/chemi-chet-prod.json')
output = Path('schema/chemi-chet-chemical-dl-reviewed.json')
source = json.loads(canonical.read_bytes())
path = '/chemicals/chemical_DL'
operation = copy.deepcopy(source['paths'][path]['get'])
assert source['openapi'] == '3.0.3'
assert operation['requestBody']['required'] is False
assert operation['requestBody']['content']['application/json']['schema'] == {
    'additionalProperties': True, 'type': 'object'
}
# The selected operation contains no references; no components are needed.
assert '"$ref"' not in json.dumps(operation)
operation['requestBody']['required'] = True
document = {
    'openapi': '3.1.0', 'info': source['info'],
    'servers': source['servers'],
    'paths': {path: {'get': operation}},
}
output.write_text(json.dumps(document, indent=2) + '\n')
expected = copy.deepcopy(source['paths'][path]['get'])
expected['requestBody']['required'] = True
assert document['paths'][path]['get'] == expected
print(hashlib.sha256(canonical.read_bytes()).hexdigest(), canonical)
print(hashlib.sha256(output.read_bytes()).hexdigest(), output)
