"""Prepare a disposable integration. The shared checkout is read only."""
import json, pathlib, subprocess, sys, tarfile, yaml
root = pathlib.Path.cwd()
work = pathlib.Path(sys.argv[1]).resolve()
assert work != root and not work.exists(), 'Use a new private directory'
work.mkdir(parents=True)
archive = subprocess.check_output(['git', 'archive', 'cd34efb4'])
import io
with tarfile.open(fileobj=io.BytesIO(archive)) as source:
    source.extractall(work, filter='data')
folder = pathlib.Path('dev/specmill-rebuild/released-facades-v42')
import shutil
shutil.copytree(folder, work / folder, dirs_exist_ok=True)
shutil.copy2('R/chet_facade_input_policy.R', work / 'R/chet_facade_input_policy.R')
config = yaml.safe_load((root / 'specmill.yml').read_text())
selected = []
for path in yaml.safe_load((root / folder / 'config.yml').read_text())['services']:
    mapping = yaml.safe_load((root / path).read_text())
    for operation in mapping['operations'].values():
        selected.append(operation['name'])
        for file in [operation['file']]:
            (work / file).unlink(missing_ok=True)
    config['services'].append(path)
for path in config['services']:
    if path.startswith(str(folder)): continue
    mapping = yaml.safe_load((work / path).read_text())
    removed = [key for key, op in mapping.get('operations', {}).items() if op.get('name') in selected]
    for key in removed:
        del mapping['operations'][key]
        mapping['selection']['include'].remove(key)
    if removed: (work / path).write_text(yaml.safe_dump(mapping, sort_keys=False))
config.setdefault('callback_files', []).extend(['dev/specmill-rebuild/rootheldrelease/callbacks.R', str(folder / 'callbacks.R')])
(work / 'specmill.yml').write_text(yaml.safe_dump(config, sort_keys=False))
hooks = yaml.safe_load((root / 'inst/hook_config.yml').read_text())
hooks.update(yaml.safe_load((root / folder / 'hook-additions.yml').read_text()))
(work / 'inst/hook_config.yml').write_text(yaml.safe_dump(hooks, sort_keys=False))
for file in ['tests/testthat/test-native_released_facades_v42.R', 'tests/testthat/fixtures/released-facades-v42-legacy.rds', 'tests/testthat/test-chemi_public_options.R']:
    shutil.copy2(root / file, work / file)
for name in selected:
    if name == 'chemi_toxprints_assays': continue
    for file in ['tests/testthat/test-' + name + '.R', 'tests/testthat/test-contract-' + name + '.R']:
        (work / file).unlink(missing_ok=True)
(work / '.facades-private-copy').write_text('Disposable Specmill integration copy\n')
print(work)
