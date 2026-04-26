# adoption-guide — 既存リポジトリへの移植手順

このテンプレートを **既存の Playwright プロジェクト** に取り込む手順です。`tomodakengo/playwright-fixture` を例に説明しますが、Cypress / Puppeteer / pytest など他フレームワーク採用プロジェクトでも考え方は同じです。

## 前提

- リポジトリで既に GitHub Issues を有効にしている
- `gh` CLI がインストール済み（`brew install gh` / `winget install gh` 等）
- リポジトリへの write 権限がある

## ステップ

### 1. ラベル定義をコピーする

```bash
mkdir -p .github
curl -L -o .github/labels.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/labels.yml
```

すでに `.github/labels.yml` がある場合は、`P-*`, `scope-*`, `severity-*`, `status-*`, `confidence-*` のセクションだけ追記してください。

### 2. ラベルを反映する

`.github/workflows/sync-labels.yml` を本テンプレからコピー:

```bash
mkdir -p .github/workflows
curl -L -o .github/workflows/sync-labels.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/workflows/sync-labels.yml
```

PR を作って main にマージ → ラベルがリポジトリに生えます。

または手動で:

```bash
gh label create "P-locator-timeout" --color "d73a4a" --description "..."
# (繰り返し)
```

### 3. Issue Template を取り込む

```bash
mkdir -p .github/ISSUE_TEMPLATE
curl -L -o .github/ISSUE_TEMPLATE/flaky-pattern.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/ISSUE_TEMPLATE/flaky-pattern.yml
# (locator-issue.yml, env-config-issue.yml, product-bug-suspect.yml も同様)
curl -L -o .github/ISSUE_TEMPLATE/config.yml \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/ISSUE_TEMPLATE/config.yml
```

`config.yml` の `contact_links` の URL は自分のリポジトリに書き換えてください。

### 4. instructions ファイルを置く

```bash
mkdir -p .github/instructions
curl -L -o .github/instructions/qa-knowledge-base.instructions.md \
  https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/.github/instructions/qa-knowledge-base.instructions.md
```

**重要**: テスト対象プロジェクトに合わせて以下をカスタマイズ:

- **Hard bans** セクション: プロジェクト固有の禁則を追加（例: 「`evaluate()` で DOM を直接操作しない」など）
- **Patterns**: 既に踏んだことのある失敗パターンがあれば追記。**空からスタートしても問題ありません**。Issue を起票しながら週次で育てていきます

### 5. AI triage を有効化する（2系統から選ぶ）

このテンプレは triage を 2 系統で提供します。**自分のチームに合うほうを選択 or 併用してください**。

| ワークフロー | エンジン | trigger | セットアップコスト |
|---|---|---|---|
| `triage-issue-copilot.yml` | GitHub Models (`gpt-4o-mini`) | `issues: opened`（自動） | **ほぼゼロ**（権限ブロックだけ） |
| `triage-issue.yml` | Claude Code Action | `workflow_dispatch`（手動） | GitHub App + API key 必要 |
| `promote-to-instructions.yml` | Claude Code Action | 週次cron | GitHub App + API key 必要 |

#### A. GitHub完結ルート（デフォルト推奨）

`triage-issue-copilot.yml` は `actions/ai-inference@v1` で GitHub Models (`gpt-4o-mini`) を呼びます。**API key 不要**、Free アカウントでも動作します。

設定済みの permissions:

```yaml
permissions:
  contents: read
  issues: write
  models: read   # ← これがあれば GITHUB_TOKEN だけで動く
```

リポジトリ Settings → Actions → General → Workflow permissions が `Read and write` になっていることだけ確認してください。

#### B. Claude Code Action ルート（高品質オプション）

`triage-issue.yml`（手動）と `promote-to-instructions.yml`（週次cron）は Claude Code Action を使います。長文・深い分析・instructions ファイルの活用が必要なときの選択肢。

##### B-1. CLI で一括セットアップ

```bash
claude /install-github-app
```

OAuth ブラウザが開けない環境（remote control / SSH / CI）では B-2 を使ってください。

##### B-2. 手動セットアップ（GitHub Web UI のみで完結）

1. **Anthropic 公式 GitHub App をインストール**
   - [https://github.com/apps/claude](https://github.com/apps/claude) を開く
   - "Install" → "Only select repositories" で対象リポジトリを選択
   - 権限（Contents R/W、Issues R/W、Pull Requests R/W）を許可

2. **`ANTHROPIC_API_KEY` を secret として登録**
   - Settings → Secrets and variables → Actions → "New repository secret"
   - Name: `ANTHROPIC_API_KEY`
   - Value: [console.anthropic.com](https://console.anthropic.com) で発行した API key

3. **PR 作成許可の有効化** (`promote-to-instructions.yml` を使う場合のみ)
   - Settings → Actions → General → "Allow GitHub Actions to create and approve pull requests" にチェック → Save

##### B-3. 手動 triage の実行方法

```bash
gh workflow run triage-issue.yml -f issue_number=42
```

または GitHub UI: Actions → "Triage issue with Claude (manual)" → "Run workflow" → issue 番号入力。

#### 動作確認

Issues タブから `🌀 Flaky pattern report` テンプレで1件起票 → 1〜2分後に triage 提案コメントが付けば成功。A ルート（GitHub Models）が自動起動します。動かない場合:

- Actions タブで `Triage issue (GitHub Models)` の run log を確認
- リポジトリ Settings → Actions → General → Workflow permissions を確認
- GitHub Models の月次 quota を消費し切っていないか（Settings → Billing → Models usage）

### 6. 既存の auto-heal pipeline と統合する

すでに [playwright-auto-heal-claude-code](https://zenn.dev/yuden/articles/playwright-auto-heal-claude-code) のような auto-heal ワークフローがある場合:

- 失敗解析プロンプトに `qa-knowledge-base.instructions.md` を Read させる
- `lookup-pattern` Skill で過去の同症状 issue を fetch させてから fix 提案
- 例（Claude Code Action 版）:

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    claude_args: '--allowedTools "Read,Edit,Bash(gh issue list:*),Bash(gh issue view:*)"'
    prompt: |
      You are an auto-heal agent for Playwright tests.
      First Read .github/instructions/qa-knowledge-base.instructions.md.
      Then look up similar past issues with `gh issue list --label P-<candidate> --state all`.
      Only after that, propose a fix that does NOT violate Hard bans.

      Failure log:
      $(cat playwright-report/results.json)
```

GitHub Models 版で同じことをしたい場合は `actions/ai-inference@v1` の `system-prompt-file: .github/instructions/qa-knowledge-base.instructions.md` を使ってください。

### 6. 最初のサンプル起票で動作確認

```bash
# 本リポジトリの examples/seed-issues.sh を流用すると 3 件サンプルが入ります
curl -L https://raw.githubusercontent.com/tomodakengo/qa-knowledge-platform/main/examples/seed-issues.sh | bash
```

GitHub の Issues タブで Pattern label が付いた Issue が 3 件作られていれば成功です。

### 7. 運用に乗せる

- **週次の triage 時間** をチームカレンダーに 30 分確保
- **昇格 PR レビュー** を QA リードのタスクに組み込む
- 1ヶ月後にラベル taxonomy の振り返り

詳しくは `docs/promotion-workflow.md` を参照。

## トラブルシュート

| 症状 | 対処 |
|---|---|
| Issue Template が GitHub UI で出てこない | `.github/ISSUE_TEMPLATE/` 配下にあるか、ファイル名が `.yml`（`.yaml` ではなく）か確認 |
| `sync-labels.yml` が動かない | リポジトリ Settings → Actions → permissions が Read and Write になっているか確認 |
| ラベルが日本語にならない | 本テンプレは英語ラベル前提。ローカライズしたい場合は `name` を変更（`P-*` 等のプレフィックスは保つ） |
