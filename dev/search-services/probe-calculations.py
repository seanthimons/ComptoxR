"""Read-only calculations using a structure retrieved from the deployed resolver."""
import hashlib, io, json, pathlib, urllib.error, urllib.request, zipfile
origin = 'https://hcd.rtpnc.epa.gov'
lookup = origin + '/api/resolver/lookup?query=DTXSID7020182'
record = json.load(urllib.request.urlopen(lookup, timeout=30))[0]
chemical = record['chemical']
assert chemical['sid'] == 'DTXSID7020182' and chemical['smiles']
result = {'lookup': lookup, 'chemical': chemical, 'probes': []}

def probe(path, body, label):
    request = urllib.request.Request(origin + path, data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
    try:
        response = urllib.request.urlopen(request, timeout=35)
    except urllib.error.HTTPError as error:
        response = error
    raw = response.read()
    row = {'label': label, 'path': path, 'request': body, 'status': response.status,
           'media': response.headers.get('Content-Type'), 'length': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    if zipfile.is_zipfile(io.BytesIO(raw)):
        archive = zipfile.ZipFile(io.BytesIO(raw))
        row['zip_members'] = archive.namelist()
        row['has_chemical_name'] = any(b'Bisphenol' in archive.read(name) for name in archive.namelist())
    else:
        row['body'] = raw.decode('utf-8', errors='replace')
    result['probes'].append(row)
    print(label, row['status'], row['media'], row['length'])

probe('/api/services/convert', {'content': chemical['smiles'], 'type': 'smiles2mol'}, 'convert-corrected')
probe('/api/services/convert', {'chemicals': [{'sid': chemical['smiles']}], 'options': {'type': 'smiles2mol'}}, 'convert-legacy')
fields = {'chemicals': json.dumps([chemical]), 'exportSafety': True, 'exportAlerts': False,
          'exportHazard': False, 'exportHazard2': False, 'exportPrediction': False}
probe('/api/services/collated_report', fields, 'collated-corrected')
# Use the wrapper's alertRequest slot to reproduce its old query -> chemicals sid mapping.
alert_request = json.dumps({'chemicals': [chemical], 'options': {}})
probe('/api/services/collated_report', {'chemicals': [{'sid': alert_request}], 'options': fields}, 'collated-legacy')
pathlib.Path('dev/search-services/calculation-evidence.json').write_text(json.dumps(result, indent=2) + '\n')
