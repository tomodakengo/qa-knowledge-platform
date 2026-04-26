#!/usr/bin/env bash
# seed-issues.sh
#
# Pattern catalogue の起点になるサンプル Issue を gh CLI で 3 件起票する。
# このリポジトリを使い始めるときに 1 度だけ実行すれば、triage / 昇格ワークフローの動作確認に使える。
#
# 前提:
#   - `gh` CLI がインストール済み・認証済み (`gh auth status` で確認)
#   - 現在のディレクトリが対象リポジトリの clone であること
#   - `.github/labels.yml` のラベルが反映済みであること
#     （未反映なら先に `gh workflow run sync-labels.yml`）

set -euo pipefail

REPO="${REPO:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "Seeding sample issues into $REPO..."

# ============================================================
# Issue 1: P-locator-timeout の典型例
# ============================================================
gh issue create \
  --repo "$REPO" \
  --title "[flaky] checkout > should complete order が CI でときどき timeout する" \
  --label "status-triage,confidence-low,P-locator-timeout,scope-single-test,severity-major" \
  --body "$(cat examples/sample-failure-logs/01-locator-timeout.md)"

# ============================================================
# Issue 2: P-strict-mode-violation の典型例
# ============================================================
gh issue create \
  --repo "$REPO" \
  --title "[locator] settings ページで Save ボタンが strict mode violation" \
  --label "status-triage,P-strict-mode-violation,scope-single-test,severity-minor" \
  --body "$(cat examples/sample-failure-logs/02-strict-mode-violation.md)"

# ============================================================
# Issue 3: P-network-race の典型例
# ============================================================
gh issue create \
  --repo "$REPO" \
  --title "[flaky] cart total assert で expected ¥3200 / received ¥0 が再現" \
  --label "status-triage,confidence-low,P-network-race,scope-fixture,severity-major" \
  --body "$(cat examples/sample-failure-logs/03-network-race.md)"

echo ""
echo "✅ Seeded 3 issues. 確認: gh issue list --label P-locator-timeout"
