#!/usr/bin/env bash
# Usage: package.sh full | package.sh delta BASE_SHA
set -euo pipefail
mkdir -p build evidence
[[ -f sfdx-project.json && -d force-app ]]
case "${1:-}" in
  full)
    sf project generate manifest --source-dir force-app --name package --output-dir build
    ;;
  delta)
    base=${2:?Base SHA is required}
    git cat-file -e "$base^{commit}"
    mkdir -p build/delta
    sf sgd source delta --from "$base" --to HEAD --generate-delta --output-dir build/delta
    cp build/delta/package/package.xml build/package.xml
    if [[ -f build/delta/destructiveChanges/destructiveChanges.xml ]]; then
      cp build/delta/destructiveChanges/destructiveChanges.xml build/destructiveChanges.xml
    fi
    ;;
  *) echo 'Usage: package.sh full|delta [BASE_SHA]' >&2; exit 1 ;;
esac
python3 - <<'CHECK'
from pathlib import Path
import xml.etree.ElementTree as E
ns={'m':'http://soap.sforce.com/2006/04/metadata'}
d=Path('build/destructiveChanges.xml')
if d.exists() and E.parse(d).findall('.//m:members',ns):
    raise SystemExit('Deletion detected. This review template blocks destructive deployments; design a separate reviewed deletion plan.')
p=E.parse('build/package.xml')
print('Metadata members:',len(p.findall('.//m:members',ns)))
CHECK
