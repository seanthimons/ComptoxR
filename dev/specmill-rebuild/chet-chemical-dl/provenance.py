"""Record exact semantic changes and omitted paths/components."""
import hashlib
import json
import subprocess
from pathlib import Path

root = Path('dev/specmill-rebuild/chet-chemical-dl')
canonical = Path('schema/chemi-chet-prod.json')
reviewed = Path('schema/chemi-chet-chemical-dl-reviewed.json')
a = json.loads(canonical.read_bytes())
b = json.loads(reviewed.read_bytes())
c = json.loads((root / 'deployed-source.json').read_bytes())
path = '/chemicals/chemical_DL'
assert a['paths'][path] == c['paths'][path]
get = a['paths'][path]['get'].copy()
get['requestBody'] = dict(get['requestBody'], required=True)
assert get == b['paths'][path]['get']
assert a['servers'] == b['servers'] == c['servers']
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
record = {
    'canonical': str(canonical), 'canonical_sha256': sha(canonical),
    'canonical_git_blob': subprocess.check_output(['git', 'rev-parse', 'HEAD:' + str(canonical)], text=True).strip(),
    'reviewed': str(reviewed), 'reviewed_sha256': sha(reviewed),
    'retrieval': json.loads((root / 'retrieval.json').read_text()),
    'sourceURL': 'https://hcd.rtpnc.epa.gov/api/chet/openapi.json',
    'server_provenance': {'copied_servers': a['servers'], 'production_origin': 'https://hcd.rtpnc.epa.gov',
                          'resolution': 'Existing .ct_server_url with chemi_burl and relative /api/chet'},
    'derivation': 'Run python3 dev/specmill-rebuild/chet-chemical-dl/derive.py from the package root.',
    'semantic_corrections': [
        {'pointer': '/openapi', 'from': '3.0.3', 'to': '3.1.0', 'reason': 'Explicit reviewed dialect upgrade permits a GET request body, with undefined interoperability semantics.'},
        {'pointer': '/paths/~1chemicals~1chemical_DL/get/requestBody/required', 'from': False, 'to': True,
         'reason': 'Deployed bodyless GET returns 400 Request body must not be empty; GET {} returns 200 CSV.'}
    ],
    'preserved': ['info', 'servers', 'GET operation except requestBody.required', 'all selected schema properties'],
    'ref_closure': [],
    'diff': {'removed_paths': sorted(set(a['paths']) - {path}),
             'removed_selected_path_fields': sorted(set(a['paths'][path]) - {'get'}),
             'removed_components': {k: sorted(v) for k, v in a['components'].items()}},
    'issue': 'https://github.com/seanthimons/specmill/issues/171',
    'integration_pr': 'https://github.com/seanthimons/ComptoxR/pull/345',
}
(root / 'provenance.json').write_text(json.dumps(record, indent=2) + '\n')
