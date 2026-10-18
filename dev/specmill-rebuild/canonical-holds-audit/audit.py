"""Reconcile the frozen checkpoint and explicit per-operation holds offline."""
import collections
import hashlib
import json
import re
import subprocess
from pathlib import Path

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]


def read(path):
    return json.loads((ROOT / path).read_bytes())


def issue(number):
    return f'https://github.com/seanthimons/specmill/issues/{number}'


def pr(number):
    return f'https://github.com/seanthimons/specmill/pull/{number}'


def disposition(status, blocker, links, evidence, next_step):
    return dict(disposition=status, blocker=blocker, links=links,
                evidence=evidence, next_step=next_step)


def classify(schema, key):
    method, path = key.split(' ', 1)
    family = Path(schema).name.removeprefix('chemi-').removesuffix('-prod.json')
    if (family == 'chet' and path.startswith('/reaction/')) or key in {
        'POST /api/resolver/resolve', 'GET /api/stdizer/groups/{id}/recursive',
        'POST /api/stdizer/records', 'POST /api/toxprints/assays',
        'POST /api/toxprints/chemicals_categories', 'POST /api/toxprints/toxprints_categories',
        'POST /api/safety/rqcodes',
    }:
        return disposition('parent_integration_excluded',
            'Parent owns nine released-capability integrations; this audit does not credit unintegrated behavior.',
            ['https://github.com/seanthimons/ComptoxR/pull/345',
             'https://github.com/seanthimons/ComptoxR/issues/352'], [],
            'Parent integrates rqcodes352 and eight original facades from b9674e5a; regenerate and verify ownership/behavior there.')
    if family == 'webtest' or family == 'safety':
        return disposition('active_child_excluded',
            'WebTEST exports and shared alerts/render source identity are owned by another active child.',
            [issue(61) + '#issuecomment-6254632814'], [],
            'Use the active child result; no duplicate wrapper or safety coverage attribution.')
    if 'freeze' in path or path in {'/api/opera/file', '/api/resolver/exportsimilaritylist', '/api/resolver/exportsimilaritymap'}:
        return disposition('release_gate',
            'Released v42 sends scalar boolean queries uppercase. Exact PR176 a656ce446fd2f4fe28184e3cad69da02e209ef26 passes five held bindings; runtime adoption still held.',
            [issue(177), pr(176)], ['dev/specmill-pr176-proof/README.md', 'dev/specmill-pr176-proof/results.json'],
            'Wait for official release and reviewed root pin update, then regenerate/retest. Moving PR head is not the exact proof.')
    if family == 'chet' and method == 'POST':
        return disposition('release_gate',
            'Released free-form URLencoded validation rejects undeclared fields. Exact PR180 d9c6f9600f075e941999fc4fafffd4ede3d90b73 passes 492 assertions for the three forms.',
            [issue(178), pr(180)], ['dev/chet-admin-auth/pr180-exact/README.md', 'dev/chet-admin-auth/pr180-exact/results.json'],
            'Wait for official release and root pin update; no deployed auth/session verification or adoption.')
    if family == 'search':
        return disposition('release_gate',
            'Exact PR179 1c3e8a34c41eba5d2a20cc46f8bc2e39abb6d18c passes search paging/state seams; current root release lacks these fixes.',
            [issue(173), pr(179)], ['dev/specmill-rebuild/pr179-finish-1c3e8a3/README.md', 'dev/specmill-rebuild/pr179-finish-1c3e8a3/test-totals.json'],
            'Wait for official release/pin and root behavior gates; 227 proof assertions cover both search and PubChem, not 227 search endpoints.')
    if family == 'toxprints':
        return disposition('generator_gap',
            'Explicit client chunk splitting is rejected for canonical object bodies; scalar fan-out cannot preserve configured chunk sizes. Legacy payload/server/auth differences also require review.',
            [issue(181)], [], 'Follow existing #181; leave chemi_toxprints_bulk unchanged. Parent owns the reproduction.')
    if family == 'amos':
        if 'batch_search' in path:
            return disposition('service_contract_hold',
                'Corrected OAS3 staging body exists, but archived minimal and populated production controls returned HTTP500. Existing facade uses incompatible generic Chemi payload/gate.',
                [issue(27) + '#issuecomment-6254000651'],
                ['dev/specmill-rebuild/sources/amos-staging-2026-10-18.json',
                 'dev/specmill-rebuild/amos-remaining-live-review.rds', 'dev/specmill-rebuild/amos-full-body-live-review.rds'],
                'Obtain a positive meaningful workbook using a declared request, then preserve public formals via a separately reviewed OAS3 subset. No raw alias or dialect splice.')
        if method == 'PUT':
            blocker = 'Canonical PUT declares only internal_id, no submitted body. Archived corrected staging omits this operation; similarly named update components do not identify its method/body contract.'
        else:
            blocker = 'Canonical Swagger2 nests type:file in a JSON body and has empty responses. Archived corrected staging omits this operation; historical issue text is not an archived replacement contract.'
        return disposition('source_contract_hold', blocker,
            [issue(27) + '#issuecomment-6254000651', issue(26)],
            ['dev/specmill-rebuild/amos-v41/inventory.json', 'dev/specmill-rebuild/sources/amos-staging-2026-10-18.json'],
            'Obtain the route-specific service-owned source/body/response contract. No invented upload/update body, Swagger2/OAS3 splice or deployed mutation probe.')
    if family == 'chet':
        return disposition('source_contract_hold',
            'Optional OAS3.0.3 GET body is ignored by generation. Selected chemical_DL proof only establishes that download; it does not justify auth/admin or chemdelete mutations.',
            [issue(171) + '#issuecomment-6253610857', issue(29)],
            ['dev/chet-admin-auth/held.json', 'dev/chet-extra/README.md', 'dev/specmill-rebuild/chet-chemical-dl/provenance.json'],
            'Require evidence for this exact GET body/requiredness and reviewed OAS3.1 subset. No deployed auth/session/mutation calls.')
    if family == 'descriptors':
        return disposition('ownership_route_hold',
            'Declared aggregate-to-RDKit fallback rejects unresolved relative OAS3 versus Swagger2 server identities before the shared explicit resolver is considered. routes support already exists; source ownership/server compatibility is the blocker.',
            [issue(61) + '#issuecomment-6252954521'],
            ['dev/specmill-rebuild/calculation-facades/evidence.json', 'dev/specmill-rebuild/canonical-holds-audit/descriptor-blockers.json'],
            'Obtain supported declared-route ownership with these sources and common resolver. v44 ownership reconciliation #170 is a different restored-output-hash fix.')
    if path.endswith('/getpubchemlist'):
        return disposition('service_contract_and_release_hold',
            'PR179 exact proof repairs paging seams, but old nested ChemicalRecord/options, records/totalRecordsCount and hidden controls disagree with declared flat Chemical plus five required query controls and service items/total. Localhost items/total still yields empty legacy result.',
            [issue(173) + '#issuecomment-6253439696', pr(179)],
            ['dev/specmill-rebuild/pr179-finish-1c3e8a3/README.md', 'dev/specmill-rebuild/remaining-facades/pubchem-live.rds'],
            'Review public-formal-preserving request/query/result correction with positive service evidence, independently of release adoption.')
    if path.endswith('/getsimilaritylist'):
        return disposition('service_contract_hold',
            'Complete declared chemicals/get_chemicals/main request returns500 due to null getter; frontend uses undocumented _chemicals. Existing _chemicals controls return only200[] and prove no nonempty similarity behavior.',
            [issue(165) + '#issuecomment-6254462836'],
            ['dev/specmill-rebuild/wave-resolved-chemical-evidence.rds'],
            'Service owner must confirm fields and a positive nonempty example; frontend spelling alone does not resolve the hold.')
    if path.endswith('/groups/preflight'):
        return disposition('isolated_candidate_ready',
            'Canonical required binary query is unresolved, but archived exact frontend route sends repeated multipart files[]. One separately reviewed subset passes official v42 validation/generation/freshness/ownership and localhost wire tests.',
            [issue(28) + '#issuecomment-6254768750'],
            ['dev/specmill-rebuild/canonical-holds-audit/source-proof.json',
             'dev/specmill-rebuild/canonical-holds-audit/frontend-evidence.json',
             'dev/specmill-rebuild/canonical-holds-audit/generation-proof.json',
             'dev/specmill-rebuild/canonical-holds-audit/test-proof.json'],
            'Parent may review/integrate one new binding, preserving held proposed name/file/body signature. Candidate has no runtime adoption or deployed upload claim.')
    if '/protocols/' in path:
        return disposition('source_contract_hold',
            'Required nested Pageable contains sort array with no encoding. Frontend POST demonstrates page/size only, not sort absent/empty/multiple/delimiters or GET behavior. GET also has unreleased scalar boolean fix.',
            [issue(31) + '#issuecomment-6253987684', issue(177)],
            ['dev/specmill-rebuild/stdizer-unbound/inventory.json'],
            'Obtain complete route-specific paging contract; do not extrapolate Spring conventions or drop sort validation.')
    # Remaining binary-query holds are deliberately distinguished by route.
    if family == 'services' and path.endswith('/caspreflight'):
        blocker = 'Required binary query files[]; archived frontend has no caspreflight caller. Evidence for preflight/universalpreflight cannot establish this route.'
    elif family == 'resolver' and path.endswith('/casharvest'):
        blocker = 'Binary query files[] plus nested request; archived frontend has no casharvest caller. No evidenced multipart metadata contract.'
    elif family == 'stdizer' and path == '/api/stdizer':
        blocker = 'Binary files[] plus nested query request, no declared JSON body. Existing facade fails missing query/chemicals before HTTP even with every argument. No exact frontend call establishes replacement behavior.'
    elif path.endswith('/groups'):
        blocker = 'Source mixes binary/nested query upload inputs with JSON LibraryGroup. Frontend has separate JSON and multipart callers, but existing bulk facade has different public fields and generic Chemical envelope. Held localhost projections prove serialization only, not public-formal-preserving group behavior.'
    elif path.endswith('/replace'):
        blocker = 'Required binary query files[]; exact frontend uses FileUploadDialog, which also appends request as JSON text. Metadata acceptance/ignored-field contract remains unverified; no body correction is promoted.'
    else:
        blocker = 'Binary query files[] plus nested request. Exact frontend sender appends request=JSON.stringify(...) as a string form field; supported typed multipart object uses application/json. No backend metadata-part contract establishes that correction.'
    assert family in {'services', 'resolver', 'stdizer', 'alerts'}, (family, key)
    return disposition('source_contract_hold', blocker, [issue(28), issue(31)],
        ['dev/search-services/deployed-source.json', 'dev/specmill-rebuild/remaining-facades/REPORT.md',
         'dev/specmill-rebuild/stdizer-unbound/inventory.json'],
        'Obtain route-specific file/metadata contract and field validation. No unvalidated text escape hatch, raw alias, inferred multipart or deployed upload/mutation call.')


progress = read('dev/specmill-rebuild/progress.json')
owned = {(e['schema'], e['operation']) for e in progress['endpoints']}
assert len(owned) == 487
rows, sources = [], {}
methods = {'get', 'post', 'put', 'patch', 'delete', 'head', 'options', 'trace'}
total = 0
for family in progress['schemas']:
    file = 'schema/' + family['schema'] + '.json'
    data = (ROOT / file).read_bytes()
    sources[file] = hashlib.sha256(data).hexdigest()
    for path, item in json.loads(data)['paths'].items():
        for method, operation in item.items():
            if method not in methods:
                continue
            total += 1
            key = method.upper() + ' ' + path
            if (file, key) in owned:
                continue
            row = {'schema': file, 'operation': key, 'operation_id': operation.get('operationId'),
                   'source_location': '#/paths/' + path.replace('~', '~0').replace('/', '~1') + '/' + method,
                   'operation_sha256': hashlib.sha256(json.dumps(operation, sort_keys=True, separators=(',', ':')).encode()).hexdigest()}
            row.update(classify(file, key))
            def normalize(route):
                return re.sub(r'^/?api/', '', route.lstrip('/')).rstrip('/')
            legacy_route = re.sub(r'/\{[^}]+\}', '', path)
            wrappers = [c['wrapper'] for c in progress['legacy_callers']
                        if c['method'] == method.upper() and normalize(c['route']) == normalize(legacy_route)]
            if 'descriptors-prod' in file:
                wrappers = ['chemi_descriptors' if method == 'get' else 'chemi_descriptors_bulk']
            if key == 'GET /reaction/database-old/{pagenum}/{searchterm}':
                wrappers = ['chemi_chet_reaction_database_old_by_pagenum_and_searchterm']
            if key == 'GET /reaction/searchcounts/{search_input}/{search_type}':
                wrappers = ['chemi_chet_reaction_searchcounts']
            if key == 'GET /api/alerts/render':
                wrappers = ['chemi_alerts_render']
            row['existing_public_wrappers'] = []
            for wrapper in wrappers:
                files = [str(f.relative_to(ROOT)) for f in (ROOT / 'R').glob('*.R')
                         if re.search(r'^' + re.escape(wrapper) + r'\s*<-\s*function\b', f.read_text(), re.M)]
                assert len(files) == 1, (wrapper, files)
                row['existing_public_wrappers'].append({'name': wrapper, 'file': files[0]})
            if row['disposition'] == 'isolated_candidate_ready':
                row['proposed_binding'] = {'name': 'chemi_stdizer_groups_preflight_post',
                    'file': 'R/chemi_stdizer_groups_preflight_post.R', 'signature': 'function(body)',
                    'snapshot': 'dev/specmill-rebuild/canonical-holds-audit/chemi_stdizer_groups_preflight_post.R.txt'}
            assert all((ROOT / p).exists() for p in row['evidence']), row
            rows.append(row)
assert total == 548 and len(rows) == 61
assert len({(r['schema'], r['operation']) for r in rows}) == 61
counts = dict(collections.Counter(r['disposition'] for r in rows))
assert counts['parent_integration_excluded'] == 9 and counts['active_child_excluded'] == 3
assert counts['isolated_candidate_ready'] == 1
subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--', '.',
                ':(exclude)dev/specmill-rebuild/canonical-holds-audit'], cwd=ROOT, check=True)
report = {
    'base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
    'checkpoint_commit': progress['commit'], 'canonical_total': total, 'checkpoint_owned': len(owned),
    'remaining_identities': len(rows), 'disposition_counts': counts,
    'canonical_sources_sha256': sources,
    'scope': 'All 61 residual canonical identities, including explicit exclusions. No root ledger update or runtime adoption.',
    'evidence_limit': 'Archived-source and blocker audit, not a fresh deployed compatibility claim. Private exact proofs are not released behavior.',
    'operations': rows,
}
(OUT / 'dispositions.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(counts, indent=2))
