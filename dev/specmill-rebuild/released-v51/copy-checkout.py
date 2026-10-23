"""Copy current tracked contents, including the applied manifest, without build caches."""
from pathlib import Path
import shutil
import subprocess
root = Path.cwd()
stage = Path.home() / '.cache/comptoxr-specmill-finish/released51-relocation/ComptoxR'
assert not stage.exists(), stage
for name in subprocess.check_output(['git', 'ls-files', '-z']).decode().split('\0'):
    if name and (root / name).is_file():
        dest = stage / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / name, dest)
lib = stage / 'dev/specmill-pilot/artifacts/toolkit-library/0.1.51'
lib.parent.mkdir(parents=True, exist_ok=True)
lib.symlink_to(root / 'dev/specmill-pilot/artifacts/toolkit-library/0.1.51', target_is_directory=True)
assert (stage / '.specmill/manifest.json').read_bytes() == (root / '.specmill/manifest.json').read_bytes()
print(stage)
