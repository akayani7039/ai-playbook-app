import importlib.util, unittest
from datetime import datetime, timezone, timedelta
from pathlib import Path
s=importlib.util.spec_from_file_location('evidence',Path(__file__).parents[2]/'scripts/ci/evidence.py')
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class PromotionChecks(unittest.TestCase):
    def record(self):return dict(kind='production-validation',sha='a'*40,release_branch='release/2026.10',baseline='b'*40,org_id='00Dexample',validation_id='0Afexample',started_at=datetime.now(timezone.utc).isoformat())
    def check(self,r):m.check_record(r,'production-validation','a'*40,'release/2026.10','b'*40,'00Dexample')
    def test_matching_validation(self):self.check(self.record())
    def test_changed_release_baseline_and_org_rejected(self):
        for key in ['sha','baseline','org_id','kind','release_branch']:
            with self.subTest(key=key):
                r=self.record();r[key]='wrong'
                with self.assertRaises(ValueError):self.check(r)
    def test_expired_validation_rejected(self):
        r=self.record();r['started_at']=(datetime.now(timezone.utc)-timedelta(days=10)).isoformat()
        with self.assertRaises(ValueError):self.check(r)
    def test_wrong_failed_or_running_workflow_rejected(self):
        r=dict(path='.github/workflows/04-uat-deployment.yml',status='completed',conclusion='success',event='workflow_dispatch',repository={'full_name':'owner/repo'})
        m.validate_run(r,'04-uat-deployment.yml','owner/repo')
        for key,value in [('path','wrong.yml'),('status','in_progress'),('conclusion','failure'),('event','push')]:
            bad={**r,key:value}
            with self.assertRaises(ValueError):m.validate_run(bad,'04-uat-deployment.yml','owner/repo')
if __name__=='__main__':unittest.main()
