"""Optional Slack notification. Sends only when a webhook secret is supplied."""
import json, os, urllib.request
url=os.environ.get('SLACK_WEBHOOK_URL','')
if url:
    from urllib.parse import urlparse
    parsed=urlparse(url)
    if parsed.scheme!='https' or parsed.hostname not in ('hooks.slack.com','hooks.slack-gov.com'):
        raise SystemExit('Unexpected Slack webhook host')
    text=f"{os.environ['GITHUB_WORKFLOW']}: {os.environ['JOB_STATUS']} | {os.environ['GITHUB_REPOSITORY']} | https://github.com/{os.environ['GITHUB_REPOSITORY']}/actions/runs/{os.environ['GITHUB_RUN_ID']}"
    req=urllib.request.Request(url,data=json.dumps({'text':text}).encode(),headers={'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(req,timeout=15) as response:
            if response.status!=200:raise RuntimeError('Slack did not acknowledge notification')
    except Exception:
        # Do not expose webhook URL or let notification failure change deployment status.
        print('::warning::Slack notification failed; review workflow evidence directly')
else:
    print('Slack webhook not configured; notification skipped')
