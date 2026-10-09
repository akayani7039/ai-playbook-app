"""Bind promotion evidence to workflow ID, frozen commit, baseline and org."""
import json, os, subprocess, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

def fail(message): raise ValueError(message)
def run(*args): return subprocess.check_output(args,text=True).strip()
def validate_run(data, workflow, repository):
    if data.get('status')!='completed' or data.get('conclusion')!='success': fail('Prerequisite run did not complete successfully')
    if data.get('path')!='.github/workflows/'+workflow: fail('Wrong prerequisite workflow')
    if data.get('event')!='workflow_dispatch': fail('Unexpected prerequisite event')
    if data.get('repository',{}).get('full_name')!=repository: fail('Wrong repository')
def check_record(data,kind,sha,branch,baseline=None,org_id=None):
    if data.get('kind')!=kind or data.get('sha')!=sha or data.get('release_branch')!=branch: fail('Evidence does not match frozen release')
    if baseline is not None and data.get('baseline')!=baseline: fail('Production baseline changed; revalidate release')
    if org_id is not None and data.get('org_id')!=org_id: fail('Validation targets a different org')
    if kind=='production-validation':
        if not str(data.get('validation_id','')).startswith('0Af'): fail('Invalid validation ID')
        created=datetime.fromisoformat(data['started_at'])
        if created.tzinfo is None: fail('Validation time must be timezone-aware')
        age=datetime.now(timezone.utc)-created
        if age<timedelta(0) or age>timedelta(days=9): fail('Validation is stale; run validation again')
def main():
    command=sys.argv[1]
    Path('evidence').mkdir(exist_ok=True)
    if command=='resolve':
        branch=os.environ['RELEASE_BRANCH']
        import re
        if not re.fullmatch(r'release/20[0-9]{2}\.(0[1-9]|1[0-2])',branch): fail('Use release/YYYY.MM')
        sha=run('git','rev-parse','origin/'+branch)
        frozen=run('git','rev-parse','refs/tags/freeze-'+branch.split('/')[1]+'^{commit}')
        if sha!=frozen: fail('Release branch moved after freeze; create a new reviewed release')
        baseline=run('git','rev-parse','origin/main')
        run('git','merge-base','--is-ancestor',baseline,sha)
        Path('build').mkdir(exist_ok=True)
        Path('build/release.json').write_text(json.dumps(dict(sha=sha,release_branch=branch,baseline=baseline)))
        with open(os.environ['GITHUB_OUTPUT'],'a') as f: f.write('sha='+sha+'\nbaseline='+baseline+'\n')
        run('git','checkout','--detach',sha)
    elif command=='fetch':
        kind=os.environ['EVIDENCE_KIND'];rid=os.environ['EVIDENCE_RUN_ID'];repo=os.environ['GITHUB_REPOSITORY']
        if not rid.isdigit(): fail('Workflow run ID must be numeric')
        workflow={'uat':'04-uat-deployment.yml','production-validation':'05-production-validation.yml'}[kind]
        data=json.loads(run('gh','api',f'repos/{repo}/actions/runs/{rid}'))
        validate_run(data,workflow,repo)
        dest=Path('build/prerequisite');dest.mkdir(exist_ok=True)
        run('gh','run','download',rid,'--repo',repo,'--name',kind+'-attestation','--dir',str(dest))
        record=json.loads((dest/'attestation.json').read_text())
        release=json.loads(Path('build/release.json').read_text())
        check_record(record,kind,release['sha'],release['release_branch'],release['baseline'],os.environ.get('EXPECTED_ORG_ID') or None)
        if str(record.get('run_id'))!=rid: fail('Evidence run ID mismatch')
        if kind=='production-validation':
            with open(os.environ['GITHUB_OUTPUT'],'a') as f:f.write('validation-id='+record['validation_id']+'\n')
    elif command=='write':
        release=json.loads(Path('build/release.json').read_text())
        record={**release,'kind':os.environ['EVIDENCE_KIND'],'run_id':os.environ['GITHUB_RUN_ID'],'org_id':os.environ['EXPECTED_ORG_ID'],'started_at':os.environ.get('VALIDATION_STARTED_AT',datetime.now(timezone.utc).isoformat())}
        if record['kind']=='production-validation':
            result=json.loads(Path('evidence/production-validation.json').read_text())
            if result.get('status')!=0 or result.get('result',{}).get('status')!='Succeeded':fail('Validation failed or is incomplete')
            record['validation_id']=result['result']['id']
        Path('evidence/attestation.json').write_text(json.dumps(record,indent=2)+'\n')
    else: fail('Unknown command')
if __name__=='__main__':main()
