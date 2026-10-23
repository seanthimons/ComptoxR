"""Verify the unpacked exact source and fingerprint the private installation."""
import hashlib
import json
import os
from pathlib import Path
import tarfile

cache = Path(os.environ.get('PR180_CACHE', '~/.cache/comptoxr-pr180-exact-test')).expanduser()
archive = cache / 'source.tar.gz'
sha256 = lambda data: hashlib.sha256(data).hexdigest()
archive_hash = sha256(archive.read_bytes())
assert archive_hash == '9ac0233be83cef396e847906567d95a56c14061172f3a32ef3ae95cb22fc5f59'
source_hashes = {}
with tarfile.open(archive) as source:
    for entry in source.getmembers():
        if entry.isfile():
            data = source.extractfile(entry).read()
            assert (cache / entry.name).read_bytes() == data, entry.name
            source_hashes[entry.name.split('/', 1)[1]] = sha256(data)
installed = cache / 'library/specmill'
assert installed.is_dir()
library_hashes = {
    str(file.relative_to(installed)): sha256(file.read_bytes())
    for file in sorted(installed.rglob('*')) if file.is_file()
}
proof = {
    'source_commit': 'd9c6f9600f075e941999fc4fafffd4ede3d90b73',
    'archive_sha256': archive_hash,
    'all_extracted_source_bytes_match_archive': True,
    'source_files': len(source_hashes),
    'source_inventory_sha256': sha256(json.dumps(source_hashes, sort_keys=True).encode()),
    'private_installed_files': library_hashes,
}
Path('dev/chet-admin-auth/pr180-exact/provenance.json').write_text(json.dumps(proof, indent=2) + '\n')
print(f'Exact archive and {len(source_hashes)} source files verified; {len(library_hashes)} private installed files fingerprinted.')
