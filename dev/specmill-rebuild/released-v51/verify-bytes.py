"""Check the adopted metadata did not change package code or archived schemas."""
from pathlib import Path
import hashlib
import json
out = Path('dev/specmill-rebuild/released-v51')
state = json.loads((out / 'before-state.json').read_text())
for group in ('core', 'schema_hashes'):
    for name, expected in state[group].items():
        assert hashlib.sha256(Path(name).read_bytes()).hexdigest() == expected, name
print(f"PASS {len(state['core'])} package core files and {len(state['schema_hashes'])} archived schema hashes unchanged")
