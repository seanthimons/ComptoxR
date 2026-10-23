"""Read-only PubChem request controls, no CTX credentials or mutations."""
import datetime
import json
import subprocess
from pathlib import Path

base = "https://pubchem.ncbi.nlm.nih.gov/rest/pug"
cases = [
    ("search_name", "/compound/name/aspirin/cids/JSON", None),
    ("search_smiles", "/compound/smiles/cids/JSON", "smiles=CC%28%3DO%29OC1%3DCC%3DCC%3DC1C%28%3DO%29O"),
    ("search_inchi", "/compound/inchi/cids/JSON", "inchi=InChI%3D1S%2FH2O%2Fh1H2"),
    ("properties_get", "/compound/cid/2244/property/MolecularFormula,XLogP/JSON", None),
    ("properties_post", "/compound/cid/property/MolecularFormula,XLogP/JSON", "cid=2244%2C6623"),
    ("synonyms_get", "/compound/cid/2244/synonyms/JSON", None),
    ("synonyms_post", "/compound/cid/synonyms/JSON", "cid=2244%2C6623"),
]
results = []
for name, path, body in cases:
    command = ["curl", "-sS", "--max-time", "30", "-w", "\n%{http_code}", base + path]
    if body is not None:
        command.extend(["--data", body])
    result = subprocess.run(command, capture_output=True, text=True)
    payload, _, status = result.stdout.rpartition("\n")
    results.append({"name": name, "url": base + path, "method": "GET" if body is None else "POST",
        "body": body, "curl_exit": result.returncode, "status": status,
        "response": payload, "stderr": result.stderr})
    print(name, status, result.returncode, flush=True)
Path(__file__).with_name("live-evidence.json").write_text(json.dumps({
    "retrieved_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "cases": results}, indent=2) + "\n")
