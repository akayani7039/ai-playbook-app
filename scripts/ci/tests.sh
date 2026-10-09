#!/usr/bin/env bash
# Application-owned npm scripts must run real tests; missing scripts fail.
set -euo pipefail
mode=${1:?jest|smoke|regression|prod-smoke}
[[ -f package.json && -f package-lock.json ]]
case "$mode" in
  jest) npm run test:unit:ci ;;
  smoke|regression|prod-smoke)
    : "${TARGET_ALIAS:?Target required}"
    # Extract token without writing org display output or auth data to artifacts.
    token=$(sf org auth show-access-token --target-org "$TARGET_ALIAS" --json | jq -er '.result.accessToken')
    [[ "$token" != '[REDACTED]'* ]]
    echo "::add-mask::$token"
    export SF_UI_ACCESS_TOKEN="$token"
    export SF_INSTANCE_URL
    SF_INSTANCE_URL=$(sf org display --target-org "$TARGET_ALIAS" --json | jq -er '.result.instanceUrl')
    npx --no-install playwright install --with-deps chromium
    npm run "test:ui:$mode"
    ;;
  *) exit 1 ;;
esac
