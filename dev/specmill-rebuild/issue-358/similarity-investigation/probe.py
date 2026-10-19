"""Bounded read-only similarity controls; run from the package root."""
import datetime
import json
import urllib.error
import urllib.request
from pathlib import Path

DIRECTORY = Path(__file__).resolve().parent
ORIGINS = {
    'development': 'https://cim-dev.sciencedataexperts.com',
    'staging': 'https://cim.sciencedataexperts.com',
    'production': 'https://hcd.rtpnc.epa.gov',
}


def probe(environment, name, body, route='getsimilaritylist'):
    url = ORIGINS[environment] + '/api/resolver/' + route
    record = dict(environment=environment, url=url,
                  retrieved_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  request=body)
    request = urllib.request.Request(url, data=json.dumps(body).encode(),
                                     headers={'Content-Type': 'application/json',
                                              'Accept': 'application/json'}, method='POST')
    try:
        response = urllib.request.urlopen(request, timeout=40)
    except urllib.error.HTTPError as error:
        response = error
    except (OSError, TimeoutError) as error:
        record['transport_error'] = str(error)
        response = None
    if response is not None:
        with response:
            record.update(status=response.code, media=response.headers.get('Content-Type'),
                          request_id=response.headers.get('X-Request-ID'))
            raw = response.read()
            try:
                record['response'] = json.loads(raw)
            except (ValueError, UnicodeDecodeError):
                record['response_text'] = raw.decode(errors='replace')
    (DIRECTORY / f'{environment}-{name}.json').write_text(json.dumps(record, indent=2) + '\n')
    result = record.get('response')
    print(environment, name, record.get('status'),
          f'rows={len(result)}' if isinstance(result, list) else json.dumps(result)[:400], flush=True)
    return record


def controls(body):
    scoring = {k: body[k] for k in ['main', '_chemicals', 'fingerprintName', 'scoreName']}
    return {
        'alias-minimal': {k: body[k] for k in ['main', '_chemicals']},
        'alias-scoring': scoring,
        'declared-full': {('get_chemicals' if k == '_chemicals' else k): v
                          for k, v in body.items()},
        'self-only': dict(body, _chemicals=[body['main']]),
        'other-only': dict(body, _chemicals=[body['_chemicals'][1]]),
        'fingerprint-only': {k: v for k, v in scoring.items() if k != 'scoreName'},
        'minimal-chemicals': dict(scoring,
            main={k: body['main'][k] for k in ['chemId', 'sid', 'smiles']},
            _chemicals=[{k: c[k] for k in ['chemId', 'sid', 'smiles']}
                        for c in body['_chemicals']]),
        'smiles-only': dict(scoring, main={'smiles': body['main']['smiles']},
            _chemicals=[{'smiles': c['smiles']} for c in body['_chemicals']]),
        'reverse-reference': dict(scoring, main=body['_chemicals'][1]),
    }


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite', choices=['baseline', 'controls'], default='baseline')
    args = parser.parse_args()
    body = json.loads((DIRECTORY / 'frontend-request.json').read_text())
    if args.suite == 'baseline':
        for environment in ORIGINS:
            probe(environment, 'frontend-full', body)
    else:
        for name, request in controls(body).items():
            probe('development', name, request)
        probe('production', 'alias-scoring', controls(body)['alias-scoring'])
