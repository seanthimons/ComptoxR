"""Check the child baseline without depending on the parent's working directory."""
import hashlib
import json
from pathlib import Path
import subprocess

baseline = '0935bb80'
tracked = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', baseline], text=True).splitlines()
protected = [p for p in tracked if p.startswith(('R/', 'schema/'))]
protected += [p for p in tracked if p in ('specmill.yml', '.specmill/manifest.json',
    'dev/specmill-lock.json', 'dev/specmill_callbacks.R', 'dev/specmill-rebuild/progress.R')
    or 'HANDOFF' in p]
proof = {}
for name in sorted(set(protected)):
    old = subprocess.check_output(['git', 'show', f'{baseline}:{name}'])
    current = Path(name).read_bytes()
    assert current == old, f'Existing/protected file changed: {name}'
    proof[name] = hashlib.sha256(current).hexdigest()
assert Path('R/chemi_resolver_ghs_list_count.R').read_bytes() == subprocess.check_output(
    ['git', 'show', f'{baseline}:R/chemi_resolver_ghs_list_count.R'])
Path('dev/resolver-extra/preservation-proof.json').write_text(json.dumps({
    'baseline': baseline, 'all_existing_R_and_schemas_unchanged': True,
    'shared_configuration_and_ownership_unchanged': True, 'sha256': proof}, indent=2) + '\n')
print(f'Preserved {len(proof)} existing/protected files byte for byte.')
