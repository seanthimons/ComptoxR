"""Build only the route supported by the archived production frontend."""
import copy
import hashlib
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
ASSET = Path('/home/sxthi/.cache/comptoxr-search-services/app.js')
CANONICAL = 'schema/chemi-stdizer-prod.json'
PATH = '/api/stdizer/groups/preflight'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write(name, data):
    (OUT / name).write_text(json.dumps(data, indent=2) + '\n')


asset = ASSET.read_bytes()
assert sha(asset) == 'dc6443e91da0ceef29f7f930cbb91671003cc3a8c983d77cbbc0bce4ca7754dd'
needles = [
    b'"preflight-url":`${e.STDIZER_URL}/groups/preflight`,"upload-url":`${e.STDIZER_URL}/groups`',
    b'const e=new FormData;this.files.forEach(t=>e.append("files[]",t,t.name)),this.$axios.post(this.preflightUrl,e)',
    b'STDIZER_URL:UP',
    b'VUE_APP_STDIZER_URL||TP)+"/stdizer"',
]
snippets = []
for needle in needles:
    offset = asset.find(needle)
    assert offset >= 0, needle
    snippets.append({'byte_offset': offset, 'text': needle.decode()})
write('frontend-evidence.json', {
    'url': 'https://hcd.rtpnc.epa.gov/js/app.2b8197a6.js',
    'sha256': sha(asset), 'archive': str(ASSET), 'snippets': snippets,
    'retrieval': 'Previously archived 2026-10-18; no network request in this derivation.',
})
review = {}
for term in [b'casharvest', b'caspreflight', b'chemdelete', b'add_aqc_spectrum', b'add_new_fact_sheet',
             b'getpubchemlist', b'getsimilaritylist', b'/protocols/${this.protocolId}?page=',
             b'e.append("request",JSON.stringify({info:t}))',
             b'e.append("request",JSON.stringify({filesInfo:',
             b'"upload-url":`${e.RESOLVER_URL}/universalharvest`',
             b'"upload-url":`${t.STDIZER_URL}/groups/${this.groupId}/replace`',
             b'"upload-url":`${e.ALERTS_URL}/groups/${this.groupId}/replace`']:
    offset = asset.find(term)
    review[term.decode()] = {'byte_offset': offset, 'found': offset >= 0}
    if offset >= 0:
        review[term.decode()]['excerpt'] = asset[max(0, offset - 50):offset + 700].decode('utf-8')
write('frontend-review.json', {
    'source': 'frontend-evidence.json', 'observations': review,
    'limit': 'No-match means absent in this archived bundle only. Callers do not prove backend acceptance or complete omitted sort/metadata contracts.',
})
source_bytes = (ROOT / CANONICAL).read_bytes()
source = json.loads(source_bytes)
original = source['paths'][PATH]['post']
assert len(original['parameters']) == 1
parameter = original['parameters'][0]
assert parameter['name'] == 'files[]' and parameter['in'] == 'query' and parameter['required']
assert parameter['schema'] == {'type': 'array', 'items': {'type': 'string', 'format': 'binary'}}
operation = copy.deepcopy(original)
del operation['parameters']
operation['requestBody'] = {
    'required': True,
    'content': {'multipart/form-data': {'schema': {
        'type': 'object', 'required': ['files[]'],
        'properties': {'files[]': copy.deepcopy(parameter['schema'])},
    }}},
}
subset = {key: copy.deepcopy(source[key]) for key in ['openapi', 'info', 'servers']}
subset['paths'] = {PATH: {'post': operation}}
refs = []


def visit(node):
    if isinstance(node, dict):
        if '$ref' in node:
            refs.append(node['$ref'])
        for value in node.values():
            visit(value)
    elif isinstance(node, list):
        for value in node:
            visit(value)


visit(subset)
closure = []
while refs:
    ref = refs.pop()
    if ref in closure:
        continue
    assert ref.startswith('#/components/schemas/')
    name = ref.removeprefix('#/components/schemas/')
    value = copy.deepcopy(source['components']['schemas'][name])
    subset.setdefault('components', {}).setdefault('schemas', {})[name] = value
    closure.append(ref)
    visit(value)
write('chemi-stdizer-reviewed-preflight.json', subset)
write('source-proof.json', {
    'canonical': CANONICAL, 'canonical_sha256': sha(source_bytes),
    'reviewed': 'chemi-stdizer-reviewed-preflight.json',
    'reviewed_sha256': sha((OUT / 'chemi-stdizer-reviewed-preflight.json').read_bytes()),
    'operation': 'POST ' + PATH, 'canonical_operation': original,
    'operation_patch': [
        {'op': 'remove', 'path': '/parameters', 'old': original['parameters']},
        {'op': 'add', 'path': '/requestBody', 'value': operation['requestBody']},
    ],
    'omitted': 'All unselected paths, top-level tags and unreferenced components.',
    'unchanged': 'Dialect, info, relative servers, operation ID, tags, responses and transitive components.',
    'local_ref_closure': sorted(closure),
    'server': 'Preserved canonical relative server; .ct_server_url chemi_burl resolves production by default.',
    'evidence': 'frontend-evidence.json',
    'issue': 'https://github.com/seanthimons/specmill/issues/28#issuecomment-6254768750',
    'deployed_upload_tested': False,
})
assert sha((ROOT / CANONICAL).read_bytes()) == sha(source_bytes)
