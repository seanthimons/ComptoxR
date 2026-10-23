"""Remove only the released and root-validated safety/render ownership hold."""
from collections import Counter
from pathlib import Path
import json
import subprocess
out = Path('dev/specmill-rebuild/released-v51')
for proof in ('generation.json', 'relocation.json', 'root-tests.json'):
    assert (out / proof).is_file(), proof
progress = json.loads(Path('dev/specmill-rebuild/progress.json').read_text())
assert sum(r['migrated'] for r in progress['schemas']) == 513
assert sum(r['total'] for r in progress['schemas']) == 548
path = Path('dev/specmill-rebuild/canonical-holds-audit/current-dispositions.json')
data = json.loads(path.read_text())
old = data['operations']
removed = [r for r in old if r['schema'] == 'schema/chemi-safety-prod.json' and r['operation'] == 'GET /api/alerts/render']
assert len(removed) == 1 and removed[0]['disposition'] == 'ownership_route_hold'
rows = [r for r in old if r not in removed]
counts = dict(Counter(r['disposition'] for r in rows))
assert counts == {'source_contract_hold': 30, 'service_contract_hold': 4, 'client_contract_hold': 1}
data.update(root_parent_commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
            migrated=513, remaining_identities=35, disposition_counts=counts, operations=rows)
path.write_text(json.dumps(data, indent=2) + '\n')
(out / 'resolved-hold.json').write_text(json.dumps(removed[0], indent=2) + '\n')
print('PASS 513 migrated; precisely one resolved hold; remaining 35 rows unchanged')
