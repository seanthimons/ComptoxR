"""Prove existing wrappers, canonical inputs and parent-owned files are untouched."""
import hashlib
import json
from pathlib import Path
import subprocess

baseline = "0935bb80"
tracked = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", baseline], text=True).splitlines()
protected = [p for p in tracked if p.startswith(("R/", "schema/", ".specmill/")) or p in (
    "dev/specmill-lock.json", "dev/install_specmill.R", "dev/specmill_callbacks.R",
    "dev/specmill-342/emit.R", "dev/specmill-rebuild/progress.md",
    "dev/specmill-rebuild/progress.json", "dev/specmill-rebuild/HANDOFF.md",
)]
proof = {}
for path in protected:
    original = subprocess.check_output(["git", "show", f"{baseline}:{path}"])
    current = Path(path).read_bytes()
    assert original == current, path
    proof[path] = hashlib.sha256(current).hexdigest()
Path("dev/specmill-rebuild/stdizer-unbound/preserved.json").write_text(
    json.dumps({"baseline": baseline, "files": proof}, indent=2) + "\n"
)
print(f"Preserved {len(proof)} existing wrappers, canonical sources and parent-owned files.")
