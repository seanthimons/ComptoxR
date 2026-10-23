"""Reproduce the reviewed six-route PUG REST subset; never rewrite NCBI bytes."""
import datetime
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "pug-rest-original.md"

def parameter(name, enum=None):
    schema = {"type": "string"}
    if enum:
        schema["enum"] = enum
    return {"name": name, "in": "path", "required": True, "schema": schema}

def operation(name, params, envelope, field, post_field=None):
    op = {"operationId": name, "parameters": params,
          "responses": {"200": {"description": "JSON result; fields may be absent on a Fault response.",
              "content": {"application/json": {"schema": {"type": "object", "additionalProperties": True,
                  "properties": {envelope: {"type": "object", "additionalProperties": True,
                      "properties": {field: {"type": "array", "items": {}}}}}}}}},
              "default": {"description": "PUG REST Fault or non-JSON service failure.",
                  "content": {"application/json": {"schema": {"type": "object", "additionalProperties": True}}}}}}
    if post_field:
        fields = post_field if isinstance(post_field, list) else [post_field]
        op["requestBody"] = {"required": True, "content": {"application/x-www-form-urlencoded": {
            "schema": {"type": "object", "properties": {key: {"type": "string"} for key in fields},
                       "additionalProperties": False}}}}
        if len(fields) == 1:
            op["requestBody"]["content"]["application/x-www-form-urlencoded"]["schema"]["required"] = fields
        else:
            op["description"] = "Use exactly the form field matching namespace, smiles or inchi."
    return op

paths = {
    "/compound/{namespace}/{query}/cids/JSON": {"get": operation("pubchem_search_get", [parameter("namespace", ["name", "inchikey", "formula"]), parameter("query")], "IdentifierList", "CID")},
    "/compound/{namespace}/cids/JSON": {"post": operation("pubchem_search_post", [parameter("namespace", ["smiles", "inchi"])], "IdentifierList", "CID", ["smiles", "inchi"])},
    "/compound/cid/{cid}/property/{properties}/JSON": {"get": operation("pubchem_properties_get", [parameter("cid"), parameter("properties")], "PropertyTable", "Properties")},
    "/compound/cid/property/{properties}/JSON": {"post": operation("pubchem_properties_post", [parameter("properties")], "PropertyTable", "Properties", "cid")},
    "/compound/cid/{cid}/synonyms/JSON": {"get": operation("pubchem_synonyms_get", [parameter("cid")], "InformationList", "Information")},
    "/compound/cid/synonyms/JSON": {"post": operation("pubchem_synonyms_post", [], "InformationList", "Information", "cid")},
}
spec = {"openapi": "3.0.3", "info": {"title": "Reviewed ComptoxR PUG REST subset", "version": "2026-10-18",
    "description": "Client-authored subset of the NCBI prose contract, not an NCBI-published OpenAPI document. Only the three retained public operation families are represented."},
    "servers": [{"url": "https://pubchem.ncbi.nlm.nih.gov/rest/pug"}], "paths": paths}
output = ROOT / "pubchem-reviewed.json"
output.write_text(json.dumps(spec, indent=2) + "\n")
ledger = {"source_url": "https://pubchem.ncbi.nlm.nih.gov/pcfe/docs/markdown/pug-rest.md",
    "retrieved_utc": datetime.datetime.fromtimestamp(SOURCE.stat().st_mtime, datetime.timezone.utc).isoformat(), "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    "output_sha256": hashlib.sha256(output.read_bytes()).hexdigest(), "operations": 6, "public_wrappers": 3,
    "review": ["Request POST Body specifies cid CSV form encoding; Input specifies namespaces and POST-only InChI.",
        "Operation, Property, Synonyms and SIDS/CIDS/AIDS sections define paths and JSON output.",
        "Only JSON and existing public wrapper namespace choices selected; other operations omitted.",
        "No server contract maxItems=100 added: 100 is existing client batching policy.",
        "String CID path/form retains CSV wire representation; public integer coercion remains client policy.",
        "Response objects remain open; no additional required success fields or assumed property types.",
        "Existing CanonicalSMILES/IsomericSMILES allowlist aliases remain client behavior; no source spelling rewrite.",
        "No canonical snapshot modified. No adoption or canonical denominator asserted."],
    "blockers": ["https://github.com/seanthimons/specmill/issues/174", "https://github.com/seanthimons/specmill/issues/175"], "adopted_operations": 0}
(ROOT / "source-ledger.json").write_text(json.dumps(ledger, indent=2) + "\n")
